`timescale 1ns/1ns

module fp_mult_tb();

    reg clk;
    reg  [31:0] a, b;
    wire [31:0] res;

    fp_mult dut (
        .clk(clk),
        .a(a),
        .b(b),
        .res(res)
    );

    initial clk = 1;
    always #1 clk = ~clk;

    initial begin
        a = 32'h0;
        b = 32'h0;
        #4

        `ifdef IVERILOG
            $dumpfile("fp_mult_tb.fst");
            $dumpvars(0, fp_mult_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- basic sanity (1.0 * 1.0 = 1.0) ---
        a = 32'h3F80_0000; b = 32'h3F80_0000; #4;
        assert(res == 32'h3F80_0000) else $display("ERROR: 1.0*1.0 expected 3F800000, got %h", res);

        // --- zero times zero (0.0 * 0.0 = 0.0) ---
        a = 32'h0000_0000; b = 32'h0000_0000; #4;
        assert(res == 32'h0000_0000) else $display("ERROR: 0.0*0.0 expected 00000000, got %h", res);

        // --- msb=1 normalize path (1.5 * 1.5 = 2.25) ---
        a = 32'h3FC0_0000; b = 32'h3FC0_0000; #4;
        assert(res == 32'h4010_0000) else $display("ERROR: 1.5*1.5 expected 40100000, got %h", res);

        // --- msb=0 normalize path (1.25 * 1.25 = 1.5625) ---
        a = 32'h3FA0_0000; b = 32'h3FA0_0000; #4;
        assert(res == 32'h3FC8_0000) else $display("ERROR: 1.25*1.25 expected 3FC80000, got %h", res);

        // --- powers of two (0.5 * 0.5 = 0.25) ---
        a = 32'h3F00_0000; b = 32'h3F00_0000; #4;
        assert(res == 32'h3E80_0000) else $display("ERROR: 0.5*0.5 expected 3E800000, got %h", res);

        // --- mixed scale (3.0 * 0.5 = 1.5) ---
        a = 32'h4040_0000; b = 32'h3F00_0000; #4;
        assert(res == 32'h3FC0_0000) else $display("ERROR: 3.0*0.5 expected 3FC00000, got %h", res);


        // --- sign: (-1.5) * 2.0 = -3.0 ---
        a = 32'hBFC0_0000; b = 32'h4000_0000; #4;
        assert(res == 32'hC040_0000) else $display("ERROR: -1.5*2.0 expected C0400000, got %h", res);

        // --- sign: (-2.0) * (-2.5) = 5.0 ---
        a = 32'hC000_0000; b = 32'hC020_0000; #4;
        assert(res == 32'h40A0_0000) else $display("ERROR: -2.0*-2.5 expected 40A00000, got %h", res);

        // --- another normalize>2 case (1.25 * 4.0 = 5.0) ---
        a = 32'h3FA0_0000; b = 32'h4080_0000; #4;
        assert(res == 32'h40A0_0000) else $display("ERROR: 1.25*4.0 expected 40A00000, got %h", res);

        // --- large numbers (1.5 * 1.5 = 2.25) ---
        a = 32'h4640_E400; b = 32'h42C8_0000; #4;
        assert(res == 32'h4996_B220) else $display("ERROR: 1.25*4.0 expected 40A00000, got %h", res);

        $display("FINISHED: fp_mult testbench complete");
        $finish;
    end

endmodule
