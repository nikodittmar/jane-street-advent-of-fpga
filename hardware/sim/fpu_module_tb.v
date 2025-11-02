`include "../src/riscv_core/control_sel.vh"
`timescale 1ns/1ns

module fpu_module_tb();

    reg  [1:0]  sel;
    reg  [31:0] op1, op2, op3;
    wire [31:0] res;

    fpu dut (
        .sel(sel),
        .op1(op1),
        .op2(op2),
        .op3(op3),
        .res(res)
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
        sel = `FPU_ADD;

        op1 = 32'h3F80_0000; op2 = 32'h3F80_0000; op3 = 32'h0000_0000; #1;
        assert(res == 32'h4000_0000) else $display("ERROR: FADD 1.0+1.0 expected 40000000, got %h", res);

        op1 = 32'hC00C_CCCD; op2 = 32'h400C_CCCD; op3 = 32'h0000_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: FADD -x + x expected 00000000, got %h", res);

        op1 = 32'h400C_CCCD; op2 = 32'h400C_CCCD; op3 = 32'h0000_0000; #1;
        assert(res == 32'h408C_CCCD) else $display("ERROR: FADD 2.2+2.2 expected 408CCCCD, got %h", res);

        op1 = 32'h0000_0000; op2 = 32'h0000_0000; op3 = 32'h0000_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: FADD 0+0 expected 00000000, got %h", res);

        op1 = 32'h0000_0000; op2 = 32'h400C_CCCD; op3 = 32'h0000_0000; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FADD 0+2.2 expected 400CCCCD, got %h", res);

        op1 = 32'h400C_CCCD; op2 = 32'h0000_0000; op3 = 32'h0000_0000; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FADD 2.2+0 expected 400CCCCD, got %h", res);

        op1 = 32'h409A_E148; op2 = 32'hBF57_0A3D; op3 = 32'h0000_0000; #1;
        assert(res == 32'h4080_0000) else $display("ERROR: FADD 4.84+(-0.84) expected 40800000, got %h", res);

        // -------------------------
        // FMADD.S
        // -------------------------
        sel = `FPU_MADD;

        op1 = 32'h400C_CCCD; op2 = 32'h400C_CCCD; op3 = 32'h0000_0000; #1;
        assert(res == 32'h409A_E148) else $display("ERROR: FMADD 2.2*2.2+0 expected 409AE148, got %h", res);

        op1 = 32'h400C_CCCD; op2 = 32'h400C_CCCD; op3 = 32'hBF57_0A3D; #1;
        assert(res == 32'h4080_0000) else $display("ERROR: FMADD 2.2*2.2+(-0.84) expected 40800000, got %h", res);

        op1 = 32'h0000_0000; op2 = 32'h400C_CCCD; op3 = 32'h400C_CCCD; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FMADD 0*2.2+2.2 expected 400CCCCD, got %h", res);

        op1 = 32'h400C_CCCD; op2 = 32'h0000_0000; op3 = 32'h400C_CCCD; #1;
        assert(res == 32'h400C_CCCD) else $display("ERROR: FMADD 2.2*0+2.2 expected 400CCCCD, got %h", res);

        $display("FINISHED: FPU testbench complete");
        $finish;
    end
endmodule
