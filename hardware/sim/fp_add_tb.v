`timescale 1ns/1ns

module fp_add_tb();

    reg  [31:0] a, b;
    wire [31:0] res;

    fp_add dut (
        .a(a),
        .b(b),
        .res(res)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("fp_add_tb.fst");
            $dumpvars(0, fp_add_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- zeros ---
        a = 32'h0000_0000; b = 32'h0000_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: 0+0 expected 00000000, got %h", res);

        // --- identity with zero ---
        a = 32'h0000_0000; b = 32'h400C_CCCD; #1; // 0 + 2.2 = 2.2
        assert(res == 32'h400C_CCCD) else $display("ERROR: 0+2.2 expected 400CCCCD, got %h", res);

        a = 32'h400C_CCCD; b = 32'h0000_0000; #1; // 2.2 + 0 = 2.2
        assert(res == 32'h400C_CCCD) else $display("ERROR: 2.2+0 expected 400CCCCD, got %h", res);

        // --- basic sanity (1.0 + 1.0 = 2.0) ---
        a = 32'h3F80_0000; b = 32'h3F80_0000; #1;
        assert(res == 32'h4000_0000) else $display("ERROR: 1.0+1.0 expected 40000000, got %h", res);

        // --- normalize right (carry out) (1.5 + 1.5 = 3.0) ---
        a = 32'h3FC0_0000; b = 32'h3FC0_0000; #1;
        assert(res == 32'h4040_0000) else $display("ERROR: 1.5+1.5 expected 40400000, got %h", res);

        // --- aligned simple (0.5 + 0.5 = 1.0) ---
        a = 32'h3F00_0000; b = 32'h3F00_0000; #1;
        assert(res == 32'h3F80_0000) else $display("ERROR: 0.5+0.5 expected 3F800000, got %h", res);

        // --- mixed scale (3.0 + (-1.5) = 1.5) ---
        a = 32'h4040_0000; b = 32'hBFC0_0000; #1;
        assert(res == 32'h3FC0_0000) else $display("ERROR: 3.0+(-1.5) expected 3FC00000, got %h", res);

        // --- exact cancellation (1.0 + (-1.0) = 0.0) ---
        a = 32'h3F80_0000; b = 32'hBF80_0000; #1;
        assert(res == 32'h0000_0000) else $display("ERROR: 1.0+(-1.0) expected 00000000, got %h", res);

        // --- typical decimal cases ---
        // 2.2 + 2.2 = 4.4
        a = 32'h400C_CCCD; b = 32'h400C_CCCD; #1;
        assert(res == 32'h408C_CCCD) else $display("ERROR: 2.2+2.2 expected 408CCCCD, got %h", res);

        // 4.84 + (-0.84) ~= 4.0  (truncation -> 0x407FD70C)
        a = 32'h409A_E148; b = 32'hBF57_AE14; #1; // 4.84 + (-0.84)
        assert(res == 32'h407F_D70C) else $display("ERROR: 4.84+(-0.84) expected 407FD70C (trunc), got %h", res);

        // --- sign tests ---
        // (-1.5) + 2.0 = 0.5
        a = 32'hBFC0_0000; b = 32'h4000_0000; #1;
        assert(res == 32'h3F00_0000) else $display("ERROR: -1.5+2.0 expected 3F000000, got %h", res);

        // (-2.0) + (-2.5) = -4.5
        a = 32'hC000_0000; b = 32'hC020_0000; #1;
        assert(res == 32'hC090_0000) else $display("ERROR: -2.0+(-2.5) expected C0900000, got %h", res);

        $display("FINISHED: fp_add testbench complete");
        $finish;
    end

endmodule
