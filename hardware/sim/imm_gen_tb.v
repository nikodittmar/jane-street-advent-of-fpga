`include "../src/riscv_core/imm.vh"
`timescale 1ns/1ns

module imm_gen_tb();

    reg [31:0] inst;
    reg [2:0] sel;
    wire [31:0] imm;

    imm_gen dut (
        .inst(inst),
        .sel(sel),

        .imm(imm)
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

    // Sign-extend utilities
    function [31:0] sext12;
        input [31:0] x;
        begin
            sext12 = {{20{x[11]}}, x[11:0]};
        end
    endfunction

    function [31:0] sext13;
        input [31:0] x;
        begin
            sext13 = {{19{x[12]}}, x[12:0]};
        end
    endfunction

    function [31:0] sext21;
        input [31:0] x;
        begin
            sext21 = {{11{x[20]}}, x[20:0]};
        end
    endfunction

    // Pack instruction bits for each type (other fields cleared)
    function [31:0] pack_I;
        input [31:0] imm12;
        reg [31:0] t;
        begin
            t = 32'b0;
            t[31:20] = imm12[11:0];
            pack_I = t;
        end
    endfunction

    function [31:0] pack_S;
        input [31:0] imm12;
        reg [31:0] t;
        begin
            t = 32'b0;
            t[31:25] = imm12[11:5];
            t[11:7]  = imm12[4:0];
            pack_S = t;
        end
    endfunction

    // imm13 is the *byte* offset with bit0 even (imm[0]=0)
    function [31:0] pack_B;
        input [31:0] imm13;
        reg [31:0] t;
        begin
            t = 32'b0;
            t[31]    = imm13[12];   // imm[12]
            t[30:25] = imm13[10:5]; // imm[10:5]
            t[11:8]  = imm13[4:1];  // imm[4:1]
            t[7]     = imm13[11];   // imm[11]
            pack_B = t;
        end
    endfunction

    // For U, imm is already the full 32-bit value with low 12 = 0
    function [31:0] pack_U;
        input [31:0] immU;
        reg [31:0] t;
        begin
            t = 32'b0;
            t[31:12] = immU[31:12]; // lower 12 are don't-care for inst; imm_gen will <<12
            pack_U = t;
        end
    endfunction

    // imm21 is the *byte* offset with bit0 even (imm[0]=0)
    function [31:0] pack_J;
        input [31:0] imm21;
        reg [31:0] t;
        begin
            t = 32'b0;
            t[31]    = imm21[20];   // imm[20]
            t[19:12] = imm21[19:12];// imm[19:12]
            t[20]    = imm21[11];   // imm[11]
            t[30:21] = imm21[10:1]; // imm[10:1]
            pack_J = t;
        end
    endfunction

    initial begin
        `ifdef IVERILOG
            $dumpfile("imm_gen_tb.fst");
            $dumpvars(0, imm_gen_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        inst = 32'b0;
        sel  = 3'b0;
        #1;

        // -------- I-type (sign-extended 12-bit) --------
        // 0
        inst = pack_I(12'h000); sel = `IMM_I; #1;
        expect_eq(imm, 32'h0000_0000, "I imm 0");
        // +2047
        inst = pack_I(12'h7FF); sel = `IMM_I; #1;
        expect_eq(imm, 32'h0000_07FF, "I imm +2047");
        // -2048
        inst = pack_I(12'h800); sel = `IMM_I; #1;
        expect_eq(imm, 32'hFFFF_F800, "I imm -2048");
        // -1
        inst = pack_I(12'hFFF); sel = `IMM_I; #1;
        expect_eq(imm, 32'hFFFF_FFFF, "I imm -1");

        // -------- S-type (sign-extended 12-bit) --------
        inst = pack_S(12'h000); sel = `IMM_S; #1;
        expect_eq(imm, 32'h0000_0000, "S imm 0");
        inst = pack_S(12'h123); sel = `IMM_S; #1;
        expect_eq(imm, 32'h0000_0123, "S imm +0x123");
        inst = pack_S(12'h800); sel = `IMM_S; #1;
        expect_eq(imm, 32'hFFFF_F800, "S imm -2048");
        inst = pack_S(12'hFFF); sel = `IMM_S; #1;
        expect_eq(imm, 32'hFFFF_FFFF, "S imm -1");

        // -------- B-type (sign-extended 13-bit, LSB=0) --------
        // +8
        inst = pack_B(13'h008); sel = `IMM_B; #1;
        expect_eq(imm, 32'h0000_0008, "B imm +8");
        // -4
        inst = pack_B(13'h1FFC); sel = `IMM_B; #1; // -4 in 13-bit two's complement
        expect_eq(imm, 32'hFFFF_FFFC, "B imm -4");
        // +4094 (max positive)
        inst = pack_B(13'h0FFE); sel = `IMM_B; #1;
        expect_eq(imm, 32'h0000_0FFE, "B imm +4094");
        // -4096 (min)
        inst = pack_B(13'h1000); sel = `IMM_B; #1;
        expect_eq(imm, 32'hFFFF_F000, "B imm -4096");

        // -------- U-type (upper 20 << 12, no sign-extend) --------
        inst = pack_U(32'h000A_B000); sel = `IMM_U; #1; // expect the same
        expect_eq(imm, 32'h000A_B000, "U imm 0x000AB000");
        inst = pack_U(32'h8000_0000); sel = `IMM_U; #1;
        expect_eq(imm, 32'h8000_0000, "U imm 0x80000000");

        // -------- J-type (sign-extended 21-bit, LSB=0) --------
        // +4
        inst = pack_J(21'h004); sel = `IMM_J; #1;
        expect_eq(imm, 32'h0000_0004, "J imm +4");
        // -8
        inst = pack_J(21'h1FFFF8); sel = `IMM_J; #1; // -8 in 21-bit two's complement
        expect_eq(imm, 32'hFFFF_FFF8, "J imm -8");
        // A mid-range positive (e.g., +0x123456 & even)
        inst = pack_J(21'h68AC); sel = `IMM_J; #1; // 0x68AC = 0b0110_1000_1010_1100 (even)
        expect_eq(imm, sext21(32'h0000_68AC), "J imm +0x68AC");

        $display("PASS: All imm_gen tests passed");
        $finish;
    end
endmodule