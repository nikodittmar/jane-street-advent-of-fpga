`timescale 1ns/1ns
`include "mem_path.vh"

module asm_tb();
  reg clk, rst;
  parameter CPU_CLOCK_PERIOD = 20;
  parameter CPU_CLOCK_FREQ   = 1_000_000_000 / CPU_CLOCK_PERIOD;

  initial clk = 0;
  always #(CPU_CLOCK_PERIOD/2) clk = ~clk;
  
  reg bp_enable = 1'b0;

  cpu # (
    .CPU_CLOCK_FREQ(CPU_CLOCK_FREQ)
  ) cpu (
    .clk(clk),
    .rst(rst),
    .bp_enable(bp_enable),
    .serial_in(1'b1),
    .serial_out()
  );

  // A task to check if the value contained in a register equals an expected value
  task check_reg;
    input [4:0] reg_number;
    input [31:0] expected_value;
    input [10:0] test_num;
    if (expected_value !== `RF_PATH.mem[reg_number]) begin
      $display("FAIL - test %d, got: %d, expected: %d for reg %d",
               test_num, `RF_PATH.mem[reg_number], expected_value, reg_number);
      $finish();
    end
    else begin
      $display("PASS - test %d, got: %d for reg %d", test_num, expected_value, reg_number);
    end
  endtask

  // A task that runs the simulation until a register contains some value
  task wait_for_reg_to_equal;
    input [4:0] reg_number;
    input [31:0] expected_value;
    while (`RF_PATH.mem[reg_number] !== expected_value)
      @(posedge clk);
  endtask

  initial begin
    $readmemh("../../software/asm/asm.hex", `BIOS_PATH.mem, 0, 4095);

    `ifndef IVERILOG
        $vcdpluson;
    `endif
    `ifdef IVERILOG
        $dumpfile("asm_tb.fst");
        $dumpvars(0, asm_tb);
    `endif
    rst = 0;

    // Reset the CPU
    rst = 1;
    repeat (10) @(posedge clk);             // Hold reset for 10 cycles
    @(negedge clk);
    rst = 0;

    // Your processor should begin executing the code in /software/asm/start.s

    // Test 1: ADD
    wait_for_reg_to_equal(20, 32'd1);
    check_reg(1, 32'd300, 1);

    // Test 2: BEQ (taken, forward)
    wait_for_reg_to_equal(20, 32'd2);
    check_reg(1, 32'd500, 2);
    check_reg(2, 32'd100, 3);

    // Test 3: BEQ (not taken, fall-through)
    wait_for_reg_to_equal(20, 32'd3);
    check_reg(1, 32'd42, 4);

    // Test 4: BNE (taken, forward)
    wait_for_reg_to_equal(20, 32'd4);
    check_reg(1, 32'd33, 5);

    // Test 5: BNE (not taken, fall-through)
    wait_for_reg_to_equal(20, 32'd5);
    check_reg(1, 32'd77, 6);

    // Test 6: BLT loop (backward branch)
    wait_for_reg_to_equal(20, 32'd6);
    check_reg(1, 32'd25, 7);

    // Test 7: JAL + JALR (call/return via x5)
    wait_for_reg_to_equal(20, 32'd7);
    check_reg(1, 32'd1234, 8);

    // Test 8: J (jal x0, ...) skips an instruction
    wait_for_reg_to_equal(20, 32'd8);
    check_reg(1, 32'd55, 9);

    // Test 9: Branch after ALU result (no hazard bug)
    wait_for_reg_to_equal(20, 32'd9);
    check_reg(1, 32'd7, 10);

    // Test 10: JAL link register used in ALU sequence (BDD-like)
    wait_for_reg_to_equal(20, 32'd10);
    check_reg(3, 32'd42, 11);

    // Test 11: JALR via register (indirect jump)
    wait_for_reg_to_equal(20, 32'd11);
    check_reg(1, 32'd321, 12);

    // Test 12: Nested branches (taken + not-taken)
    wait_for_reg_to_equal(20, 32'd12);
    check_reg(1, 32'd3, 13);

    // Test 13: BLT vs BLTU (signed vs unsigned)
    wait_for_reg_to_equal(20, 32'd13);
    check_reg(1, 32'd5, 14);
    check_reg(12, 32'd7, 15);

    $display("ALL ASSEMBLY TESTS PASSED!");
    $finish();
  end

  initial begin
    // Give more headroom for the loops and extra tests
    repeat (2000) @(posedge clk);
    $display("Failed: timing out");
    $fatal();
  end
endmodule
