`timescale 1ns/1ns

`include "../src/riscv_core/opcode.vh"
`include "mem_path.vh"

// This testbench tests a specific FPU data hazard case:
// back-to-back FMADD instructions where the second FMADD
// uses the *result* of the first FMADD as fs3.
//
//  fmadd.s f5, f1, f2, f3   ; f5 = f1 * f2 + f3
//  fmadd.s f6, f1, f2, f5   ; f6 = f1 * f2 + f5 (fs3 hazard, should be forwarded)
//
// With:
//   f1 = 2.0
//   f2 = 3.0
//   f3 = 1.0
//
// We expect:
//   f5 = 2.0 * 3.0 + 1.0 = 7.0   -> 0x40E00000
//   f6 = 2.0 * 3.0 + 7.0 = 13.0  -> 0x41500000
//
// This specifically checks forwarding for fs3 on back-to-back FMADDs.

module fpu_madd_tb();
  reg clk, rst;
  parameter CPU_CLOCK_PERIOD = 20;
  parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

  initial clk = 0;
  always #(CPU_CLOCK_PERIOD/2) clk = ~clk;

  wire [31:0] csr;  // unused, but keep for interface consistency
  reg bp_enable = 1'b0;

  // Init PC with 32'h1000_0000 -- address space of IMem
  cpu #(
    .CPU_CLOCK_FREQ(CPU_CLOCK_FREQ),
    .RESET_PC(32'h1000_0000)
  ) cpu (
    .clk       (clk),
    .rst       (rst),
    .bp_enable (bp_enable),
    .serial_in (1'b1),
    .serial_out()
  );

  wire [31:0] timeout_cycle = 1000;

  // Reset IMem, DMem, and RegFile before running a new test
  task reset;
    integer i;
    begin
      for (i = 0; i < `RF_PATH.DEPTH; i = i + 1) begin
        `RF_PATH.mem[i]  = 0;
        `FPRF_PATH.mem[i] = 0;
      end
      for (i = 0; i < `DMEM_PATH.DEPTH; i = i + 1) begin
        `DMEM_PATH.mem[i] = 0;
      end
      for (i = 0; i < `IMEM_PATH.DEPTH; i = i + 1) begin
        `IMEM_PATH.mem[i] = 0;
      end
    end
  endtask

  task reset_cpu;
    begin
      @(negedge clk);
      rst = 1;
      @(negedge clk);
      rst = 0;
    end
  endtask

  reg [31:0] cycle;
  reg        done;
  reg [31:0]  current_test_id = 0;
  reg [255:0] current_test_type;
  reg [31:0]  current_output;
  reg [31:0]  current_result;
  reg         all_tests_passed = 0;

  // Check for timeout
  initial begin
    while (all_tests_passed === 0) begin
      @(posedge clk);
      if (cycle === timeout_cycle) begin
        $display("[Failed] Timeout at [%0t] test %s, expected_result = %h, got = %h",
                 $time, current_test_type, current_result, current_output);
        $finish();
      end
    end
  end

  always @(posedge clk) begin
    if (done === 0)
      cycle <= cycle + 1;
    else
      cycle <= 0;
  end

  // Check result of FPRF
  task check_result_fprf;
    input [31:0]  rf_wa;
    input [31:0]  result;
    input [255:0] test_type;
    begin
      done              = 0;
      current_test_id   = current_test_id + 1;
      current_test_type = test_type;
      current_result    = result;
      while (`FPRF_PATH.mem[rf_wa] !== result) begin
        current_output = `FPRF_PATH.mem[rf_wa];
        @(posedge clk);
      end
      cycle = 0;
      done  = 1;
      $display("[%0d] Test %s passed!", current_test_id, test_type);
    end
  endtask

  integer i;

  reg [14:0] INST_ADDR;
  reg [4:0]  RS1, RS2, RS3;
  reg [31:0] RD1, RD2, RD3;

  initial begin
    `ifndef IVERILOG
      $vcdpluson;
    `endif
    `ifdef IVERILOG
      $dumpfile("fpu_madd_tb.fst");
      $dumpvars(0, fpu_madd_tb);
    `endif

    rst = 0;
    cycle = 0;
    done  = 0;

    // Global reset
    rst = 1;
    repeat (10) @(posedge clk);
    @(negedge clk);
    rst = 0;

    // Clear memories and register files
    reset();

    // -------------------------------
    // FMADD -> FMADD fs3 forwarding
    // -------------------------------
    // f1 = 2.0, f2 = 3.0, f3 = 1.0
    RS1 = 5'd1; RD1 = 32'h40000000; // 2.0
    RS2 = 5'd2; RD2 = 32'h40400000; // 3.0
    RS3 = 5'd3; RD3 = 32'h3f800000; // 1.0

    `FPRF_PATH.mem[RS1] = RD1;
    `FPRF_PATH.mem[RS2] = RD2;
    `FPRF_PATH.mem[RS3] = RD3;

    // Clear destination regs
    `FPRF_PATH.mem[5'd5] = 32'h0;
    `FPRF_PATH.mem[5'd6] = 32'h0;

    INST_ADDR = 14'h0000;

    // fmadd.s f5, f1, f2, f3  ; f5 = 2*3 + 1 = 7.0 = 0x40E00000
    `IMEM_PATH.mem[INST_ADDR] =
        32'h1820F2C3;

    // fmadd.s f6, f1, f2, f5  ; f6 = 2*3 + f5 = 13.0 = 0x41500000
    // opcode=0x43, rd=6, rs1=1, rs2=2, rs3=5, rm=7, funct2=0
    `IMEM_PATH.mem[INST_ADDR + 1] =
        32'h2820F343;

    // Reset CPU so it starts executing from RESET_PC/IMEM
    reset_cpu();

    // First make sure f5 is correct (basic fmadd)
    check_result_fprf(5'd5, 32'h40E00000, "FMADD #1 result (f5)");

    // Then check that second FMADD saw forwarded fs3 = f5
    check_result_fprf(5'd6, 32'h41500000, "FMADD #2 fs3 forwarding (f6)");

    // If we reached here, the specific hazard test passed
    all_tests_passed = 1'b1;

    repeat (100) @(posedge clk);
    $display("All FMADD fs3 forwarding tests passed!");
    $finish();
  end

endmodule
