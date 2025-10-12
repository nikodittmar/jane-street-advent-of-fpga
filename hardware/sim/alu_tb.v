`include "../src/riscv_core/alu_sel.vh"
`timescale 1ns/1ns

module alu_tb();

    reg [31:0] a, b;
    reg [3:0] sel;
    wire [31:0] res;

    alu dut (
        .a(a),
        .b(b),
        .sel(sel),

        .res(res)
    );

    // Helpers
    task expect_eq;
        input [31:0] got;
        input [31:0] exp;
        input [8*128-1:0] msg;
        begin
            if (got != exp) begin 
                $display("FAIL: %s\ngot %h, expected %h @%0t", msg, got, exp, $time);
                $fatal(1);
            end
        end
    endtask

    initial begin
        `ifdef IVERILOG
            $dumpfile("alu_tb.fst");
            $dumpvars(0, alu_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- ADD ---
        sel = `ALU_ADD; a = 32'd1; b = 32'd2; #1;  expect_eq(res, 32'd3, "ADD 1+2");
        sel = `ALU_ADD; a = 32'hFFFF_FFFF; b = 32'd1; #1; expect_eq(res, 32'h0000_0000, "ADD wraparound");

        // --- SUB ---
        sel = `ALU_SUB; a = 32'd1; b = 32'd2; #1;  expect_eq(res, 32'hFFFF_FFFF, "SUB 1-2");
        sel = `ALU_SUB; a = 32'h8000_0000; b = 32'h8000_0000; #1; expect_eq(res, 32'h0, "SUB equal -> 0");

        // --- AND / OR / XOR ---
        sel = `ALU_AND; a = 32'hF0F0_1234; b = 32'h0FF0_F0F0; #1; expect_eq(res, 32'h00F0_1030, "AND");
        sel = `ALU_OR ; a = 32'hF0F0_1234; b = 32'h0FF0_F0F0; #1; expect_eq(res, 32'hFFF0_F2F4, "OR");
        sel = `ALU_XOR; a = 32'hAAAA_5555; b = 32'hFFFF_0000; #1; expect_eq(res, 32'h5555_5555, "XOR");

        // --- Shifts (mask B[4:0]) ---
        sel = `ALU_SLL; a = 32'h0000_0001; b = 32'd4;  #1; expect_eq(res, 32'h0000_0010, "SLL by 4");
        sel = `ALU_SLL; a = 32'h0000_0001; b = 32'd32; #1; expect_eq(res, 32'h0000_0001, "SLL mask 32->0 shift");

        sel = `ALU_SRL; a = 32'h8000_0000; b = 32'd1;  #1; expect_eq(res, 32'h4000_0000, "SRL by 1");
        sel = `ALU_SRL; a = 32'h8000_0000; b = 32'd33; #1; expect_eq(res, 32'h4000_0000, "SRL mask 33->1 shift");

        sel = `ALU_SRA; a = 32'h8000_0000; b = 32'd1;  #1; expect_eq(res, 32'hC000_0000, "SRA by 1");
        sel = `ALU_SRA; a = 32'hFFFF_FFFF; b = 32'd4;  #1; expect_eq(res, 32'hFFFF_FFFF, "SRA keep sign");

        // --- SLT (signed) ---
        sel = `ALU_SLT; a = 32'hFFFF_FFFF; b = 32'd1;       #1; expect_eq(res, 32'd1, "SLT: -1 < 1 (true)");
        sel = `ALU_SLT; a = 32'd1;        b = 32'hFFFF_FFFF;#1; expect_eq(res, 32'd0, "SLT:  1 < -1 (false)");
        sel = `ALU_SLT; a = 32'h8000_0000; b = 32'd0;       #1; expect_eq(res, 32'd1, "SLT: INT_MIN < 0");

        // --- BSEL passthrough ---
        sel = `ALU_BSEL; a = 32'hDEAD_BEEF; b = 32'hCAFE_BABE; #1; expect_eq(res, 32'hCAFE_BABE, "BSEL");
        
        $display("PASS: All alu tests passed");
        $finish;
    end
endmodule