`timescale 1ns/1ns

module fp_cvt_tb();

    reg clk;
    reg  [31:0] in;   // signed int32 input (bit-pattern)
    wire [31:0] res;  // float32 output

    fp_cvt dut (
        .clk(clk),
        .in(in),
        .res(res)
    );

    initial clk = 1;
    always #1 clk = ~clk;

    initial begin
        in = 32'h0;
        #4

        `ifdef IVERILOG
            $dumpfile("fp_cvt_tb.fst");
            $dumpvars(0, fp_cvt_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- zero ---
        in = 32'd0; #4;
        assert(res == 32'h0000_0000) else $display("ERROR: 0  -> expected 00000000, got %h", res);

        // --- +/- 1 ---
        in = 32'd1; #4;
        assert(res == 32'h3F80_0000) else $display("ERROR: 1  -> expected 3F800000, got %h", res);

        in = $signed(-1); #4;
        assert(res == 32'hBF80_0000) else $display("ERROR: -1 -> expected BF800000, got %h", res);

        // --- small powers / small ints ---
        in = 32'd2; #4;
        assert(res == 32'h4000_0000) else $display("ERROR: 2  -> expected 40000000, got %h", res);

        in = $signed(-2); #4;
        assert(res == 32'hC000_0000) else $display("ERROR: -2 -> expected C0000000, got %h", res);

        in = 32'd3; #4;
        assert(res == 32'h4040_0000) else $display("ERROR: 3  -> expected 40400000, got %h", res);

        in = 32'd5; #4;
        assert(res == 32'h40A0_0000) else $display("ERROR: 5  -> expected 40A00000, got %h", res);

        // --- medium powers ---
        in = 32'd256; #4;    // 2^8
        assert(res == 32'h4380_0000) else $display("ERROR: 256 -> expected 43800000, got %h", res);

        in = $signed(-256); #4;
        assert(res == 32'hC380_0000) else $display("ERROR: -256 -> expected C3800000, got %h", res);

        in = 32'd1024; #4;   // 2^10
        assert(res == 32'h4480_0000) else $display("ERROR: 1024 -> expected 44800000, got %h", res);

        // --- assorted exact integers ---
        in = 32'd10; #4;
        assert(res == 32'h4120_0000) else $display("ERROR: 10 -> expected 41200000, got %h", res);

        in = $signed(-10); #4;
        assert(res == 32'hC120_0000) else $display("ERROR: -10 -> expected C1200000, got %h", res);

        in = 32'd15; #4;
        assert(res == 32'h4170_0000) else $display("ERROR: 15 -> expected 41700000, got %h", res);

        // --- extreme exact power-of-two (INT_MIN) ---
        in = 32'h8000_0000; #4; // -2^31 as bit-pattern
        assert(res == 32'hCF00_0000) else $display("ERROR: -2^31 -> expected CF000000, got %h", res);

        // --- 2^24 is exactly representable in float32 ---
        in = 32'd16_777_216; #4; // 2^24
        assert(res == 32'h4B80_0000) else $display("ERROR: 2^24 -> expected 4B800000, got %h", res);

        $display("FINISHED: fp_cvt testbench complete");
        $finish;
    end

endmodule
