`include "../src/riscv_core/control/control_sel.vh"
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

    initial begin
        `ifdef IVERILOG
            $dumpfile("alu_tb.fst");
            $dumpvars(0, alu_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- ADD ---
        sel = `ALU_ADD; a = 32'd1; b = 32'd2; #1;
        assert(res == 32'd3) else $display("ERROR: ADD 1+2 expected 3, got %h", res);

        sel = `ALU_ADD; a = 32'hFFFF_FFFF; b = 32'd1; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: ADD wraparound expected 0, got %h", res);

        // --- SUB ---
        sel = `ALU_SUB; a = 32'd1; b = 32'd2; #1;
        assert(res == 32'hFFFF_FFFF) else $display("ERROR: SUB 1-2 expected -1, got %h", res);

        sel = `ALU_SUB; a = 32'h8000_0000; b = 32'h8000_0000; #1;
        assert(res == 32'h0) else $display("ERROR: SUB equal expected 0, got %h", res);

        // --- AND / OR / XOR ---
        sel = `ALU_AND; a = 32'hF0F0_1234; b = 32'h0FF0_F0F0; #1;
        assert(res == 32'h00F0_1030) else $display("ERROR: AND mismatch, got %h", res);

        sel = `ALU_OR; a = 32'hF0F0_1234; b = 32'h0FF0_F0F0; #1;
        assert(res == 32'hFFF0_F2F4) else $display("ERROR: OR mismatch, got %h", res);

        sel = `ALU_XOR; a = 32'hAAAA_5555; b = 32'hFFFF_0000; #1;
        assert(res == 32'h5555_5555) else $display("ERROR: XOR mismatch, got %h", res);

        // --- SHIFTS ---
        sel = `ALU_SLL; a = 32'h0000_0001; b = 32'd4; #1;
        assert(res == 32'h0000_0010) else $display("ERROR: SLL by 4 got %h", res);

        sel = `ALU_SLL; a = 32'h0000_0001; b = 32'd32; #1;
        assert(res == 32'h0000_0001) else $display("ERROR: SLL shift mask failed, got %h", res);

        sel = `ALU_SRL; a = 32'h8000_0000; b = 32'd1; #1;
        assert(res == 32'h4000_0000) else $display("ERROR: SRL by 1 failed, got %h", res);

        sel = `ALU_SRL; a = 32'h8000_0000; b = 32'd33; #1;
        assert(res == 32'h4000_0000) else $display("ERROR: SRL mask failed, got %h", res);

        sel = `ALU_SRA; a = 32'h8000_0000; b = 32'd1; #1;
        assert(res == 32'hC000_0000) else $display("ERROR: SRA by 1 failed, got %h", res);

        sel = `ALU_SRA; a = 32'hFFFF_FFFF; b = 32'd4; #1;
        assert(res == 32'hFFFF_FFFF) else $display("ERROR: SRA sign extend failed, got %h", res);

        // --- SLT ---
        sel = `ALU_SLT; a = 32'hFFFF_FFFF; b = 32'd1; #1;
        assert(res == 32'd1) else $display("ERROR: SLT -1 < 1 failed, got %h", res);

        sel = `ALU_SLT; a = 32'd1; b = 32'hFFFF_FFFF; #1;
        assert(res == 32'd0) else $display("ERROR: SLT 1 < -1 failed, got %h", res);

        sel = `ALU_SLT; a = 32'h8000_0000; b = 32'd0; #1;
        assert(res == 32'd1) else $display("ERROR: SLT INT_MIN < 0 failed, got %h", res);

        // --- BSEL ---
        sel = `ALU_BSEL; a = 32'hDEAD_BEEF; b = 32'hCAFE_BABE; #1;
        assert(res == 32'hCAFE_BABE) else $display("ERROR: BSEL failed, got %h", res);

        $display("FINISHED: ALU testbench complete");
        $finish;
    end
endmodule
