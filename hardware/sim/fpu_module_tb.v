`include "../src/riscv_core/control_sel.vh"
`timescale 1ns/1ns

module fpu_module_tb();

    reg  [2:0]  sel;
    reg  [31:0] a, b, c;
    wire [31:0] res;
    wire busy;

    fpu dut (
        .a(a),
        .b(b),
        .c(c),
        .sel(sel),
        .res(res),
        .busy(busy)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("fpu_module_tb.fst");
            $dumpvars(0, fpu_module_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // -------------------------
        // FADD.S
        // -------------------------
        sel = `FPU_ADD; c = 32'h0; a = 32'h0;

        a = 32'h3F80_0000; b = 32'h3F80_0000; #1;
        assert(res == 32'h4000_0000) else $display("ERROR: FADD 1.0+1.0 expected 40000000, got %h", res);

        a = 32'hC00C_CCCD; b = 32'h400C_CCCD; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: FADD -x + x expected 00000000, got %h", res);

        a = 32'h400C_CCCD; b = 32'h400C_CCCD; #1;
        assert(res == 32'h408C_CCCD) else $display("ERROR: FADD 2.2+2.2 expected 408CCCCD, got %h", res);

        a = 32'h0000_0000; b = 32'h0000_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: FADD 0+0 expected 00000000, got %h", res);

        a = 32'h0000_0000; b = 32'h400C_CCCD; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FADD 0+2.2 expected 400CCCCD, got %h", res);

        a = 32'h400C_CCCD; b = 32'h0000_0000; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FADD 2.2+0 expected 400CCCCD, got %h", res);

        a = 32'h409A_E148; b = 32'hBF57_0A3D; #1;
        assert(res == 32'h4080_0000) else $display("ERROR: FADD 4.84+(-0.84) expected 40800000, got %h", res);

        // -------------------------
        // FMADD.S
        // -------------------------
        sel = `FPU_MADD; a = 32'h0;

        a = 32'h400C_CCCD; b = 32'h400C_CCCD; c = 32'h0000_0000; #1;
        assert(res == 32'h409A_E148) else $display("ERROR: FMADD 2.2*2.2+0 expected 409AE148, got %h", res);

        a = 32'h400C_CCCD; b = 32'h400C_CCCD; c = 32'hBF57_0A3D; #1;
        assert(res == 32'h4080_0000) else $display("ERROR: FMADD 2.2*2.2+(-0.84) expected 40800000, got %h", res);

        a = 32'h0000_0000; b = 32'h400C_CCCD; c = 32'h400C_CCCD; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FMADD 0*2.2+2.2 expected 400CCCCD, got %h", res);

        a = 32'h400C_CCCD; b = 32'h0000_0000; c = 32'h400C_CCCD; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FMADD 2.2*0+2.2 expected 400CCCCD, got %h", res);

        a = 32'h0000_0000; b = 32'h0000_0000; c = 32'h0000_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: FMADD 0*0+0 expected 00000000, got %h", res);


        // -------------------------
        // FSGNJ.S
        // -------------------------
        sel = `FPU_SGNJ; c = 32'h0; a = 32'h0;

        a = 32'h408E_147B; b = 32'hBECC_CCCD; #1;
        assert(res == 32'hC08E_147B) else $display("ERROR: FSGNJ expected C08E147B, got %h", res);

        a = 32'hBECC_CCCD; b = 32'h408E_147B; #1;
        assert(res == 32'h3ECC_CCCD) else $display("ERROR: FSGNJ expected 3ECCCCCD, got %h", res);

        // -------------------------
        // FCVT.S.W
        // -------------------------
        sel = `FPU_CVT; a = 32'h0; b = 32'h0; c = 32'h0;

        a = 32'h0000_000F; #1;
        assert(res == 32'h4170_0000) else $display("ERROR: FCVT.S.W 0x0000000F expected 41700000, got %h", res);

        a = 32'hFFFF_FFF1; #1;
        assert(res == 32'hC170_0000) else $display("ERROR: FCVT.S.W 0xFFFFFFF1 expected C1700000, got %h", res);

        a = 32'h0000_05DC; #1;
        assert(res == 32'h44BB_8000) else $display("ERROR: FCVT.S.W 0x000005DC expected 44BB8000, got %h", res);

        a = 32'hFFFF_FC13; #1;
        assert(res == 32'hC47B_4000) else $display("ERROR: FCVT.S.W 0xFFFFFC13 expected C47B4000, got %h", res);

        $display("FINISHED: FPU testbench complete");
        $finish;
    end
endmodule
