`include "../src/riscv_core/control_sel.vh"
`timescale 1ns/1ns

module mux_tb();

    // Match the usage pattern: 32-bit databus, 3-input PC mux
    localparam int WIDTH       = 32;
    localparam int NUM_INPUTS  = 3;

    // Local select indices (no global constants)
    localparam int PC_4   = 0;
    localparam int PC_ALU = 1;
    localparam int PC_TGT = 2;

    // "Upstream" signals like in your pipeline
    reg  [WIDTH-1:0] ex_pc;
    reg  [WIDTH-1:0] ex_alu;
    reg  [WIDTH-1:0] id_target;

    // Packed input bus and select
    wire [NUM_INPUTS*WIDTH-1:0] pc_mux_in;
    reg  [$clog2(NUM_INPUTS)-1:0] pc_sel;

    // DUT output
    wire [WIDTH-1:0] next_pc;

    // Pack exactly like your intended usage
    assign pc_mux_in[PC_4   * WIDTH +: WIDTH] = ex_pc + 32'd4;
    assign pc_mux_in[PC_ALU * WIDTH +: WIDTH] = ex_alu;
    assign pc_mux_in[PC_TGT * WIDTH +: WIDTH] = id_target;

    // DUT
    mux #(
        .NUM_INPUTS(NUM_INPUTS),
        .WIDTH(WIDTH)
    ) pc_mux (
        .in(pc_mux_in),
        .sel(pc_sel),
        .out(next_pc)
    );

    // Helpers
    task check(input [WIDTH-1:0] exp, input [WIDTH-1:0] got, input [255:0] msg);
        begin
            assert(got === exp) else $display("ERROR: %s expected %h, got %h", msg, exp, got);
        end
    endtask

    initial begin
        `ifdef IVERILOG
            $dumpfile("mux_tb.fst");
            $dumpvars(0, mux_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // Initialize sources
        ex_pc     = 32'h1000_0000;
        ex_alu    = 32'h2000_0000;
        id_target = 32'h3000_0000;
        pc_sel    = {($clog2(NUM_INPUTS)){1'b0}};
        #1;

        // --- Select PC+4 path ---
        pc_sel = PC_4; #1;
        check(ex_pc + 32'd4, next_pc, "PC_4 initial");

        // Change ex_pc and verify output tracks the slice
        ex_pc = 32'h1000_0010; #1;
        check(ex_pc + 32'd4, next_pc, "PC_4 after ex_pc change");

        // --- Select ALU path ---
        pc_sel = PC_ALU; #1;
        check(ex_alu, next_pc, "PC_ALU initial");

        // Update ALU result and confirm it reflects immediately
        ex_alu = 32'hABCD_EF01; #1;
        check(ex_alu, next_pc, "PC_ALU after ex_alu change");

        // --- Select Target path ---
        pc_sel = PC_TGT; #1;
        check(id_target, next_pc, "PC_TGT initial");

        // Update target and verify
        id_target = 32'h4000_1234; #1;
        check(id_target, next_pc, "PC_TGT after id_target change");

        // --- Mixed pattern checks to ensure no aliasing in packed bus ---
        ex_pc     = 32'h0000_0100;
        ex_alu    = 32'h0000_0200;
        id_target = 32'h0000_0300; #1;

        pc_sel = PC_4;   #1; check(ex_pc + 32'd4, next_pc, "PC_4 mixed");
        pc_sel = PC_ALU; #1; check(ex_alu,         next_pc, "PC_ALU mixed");
        pc_sel = PC_TGT; #1; check(id_target,      next_pc, "PC_TGT mixed");

        // --- Stress: rapid toggles on sel with changing sources ---
        ex_pc     = 32'hDEAD_BEEF;
        ex_alu    = 32'hCAFE_BABE;
        id_target = 32'h0;         #1;

        pc_sel = PC_ALU; #1; check(32'hCAFE_BABE, next_pc, "Toggle sel ALU");
        pc_sel = PC_4;   #1; check(32'hDEAD_BEF3, next_pc, "Toggle sel PC_4"); // BEEF + 4 = BEF3
        id_target = 32'h1234_5678;
        pc_sel = PC_TGT; #1; check(32'h1234_5678, next_pc, "Toggle sel TGT");

        $display("FINISHED: mux testbench complete");
        $finish;
    end

endmodule
