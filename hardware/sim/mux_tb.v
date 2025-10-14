`timescale 1ns/1ns

module mux_tb;

    // -------- Instance 1: 4 inputs x 32 bits --------
    localparam WIDTH1 = 32;
    localparam N1     = 4;

    reg  [N1*WIDTH1-1:0] in1;
    reg  [$clog2(N1)-1:0] sel1;   // 2 bits
    wire [WIDTH1-1:0]     out1;

    mux #(.NUM_INPUTS(N1), .WIDTH(WIDTH1)) dut1 (
        .in(in1),
        .sel(sel1),
        .out(out1)
    );

    // -------- Instance 2: 5 inputs (non power-of-2) x 8 bits --------
    localparam WIDTH2 = 8;
    localparam N2     = 5;

    reg  [N2*WIDTH2-1:0] in2;
    reg  [$clog2(N2)-1:0] sel2;   // 3 bits
    wire [WIDTH2-1:0]     out2;

    mux #(.NUM_INPUTS(N2), .WIDTH(WIDTH2)) dut2 (
        .in(in2),
        .sel(sel2),
        .out(out2)
    );

    // ------------ Waves ------------
    initial begin
        `ifdef IVERILOG
            $dumpfile("mux_tb.fst");
            $dumpvars(0, mux_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif
    end

    // ------------ Tests for dut1 (4x32) ------------
    integer i;
    initial begin
        // Pack as {in3, in2, in1, in0}
        in1 = {
            32'hDEAD_BEEF, // index 3
            32'hCAFE_BABE, // index 2
            32'h0123_4567, // index 1
            32'h89AB_CDEF  // index 0
        };

        // Select each input and check (use 'd literals)
        sel1 = 2'd0; #1;
        assert(out1 == 32'h89AB_CDEF) else $display("ERROR[dut1]: sel=0 expected 0x89ABCDEF, got %h", out1);

        sel1 = 2'd1; #1;
        assert(out1 == 32'h0123_4567) else $display("ERROR[dut1]: sel=1 expected 0x01234567, got %h", out1);

        sel1 = 2'd2; #1;
        assert(out1 == 32'hCAFE_BABE) else $display("ERROR[dut1]: sel=2 expected 0xCAFEBABE, got %h", out1);

        sel1 = 2'd3; #1;
        assert(out1 == 32'hDEAD_BEEF) else $display("ERROR[dut1]: sel=3 expected 0xDEADBEEF, got %h", out1);

        // Change an input after it is selected (combinational update)
        sel1 = 2'd2; #1;
        assert(out1 == 32'hCAFE_BABE) else $display("ERROR[dut1]: before update sel=2, got %h", out1);

        in1[2*WIDTH1 +: WIDTH1] = 32'h1111_2222; #1; // update lane 2
        assert(out1 == 32'h1111_2222) else $display("ERROR[dut1]: dynamic update lane2 expected 0x11112222, got %h", out1);

        // Sweep over all lanes and compare against reference slice
        for (i = 0; i < N1; i = i + 1) begin
            sel1 = i[1:0]; #1;  // bit-slice loop var to 2 bits
            assert(out1 == in1[i*WIDTH1 +: WIDTH1])
                else $display("ERROR[dut1]: sweep sel=%0d expected %h, got %h",
                              i, in1[i*WIDTH1 +: WIDTH1], out1);
        end

        $display("PASS: dut1 (4x32) basic selection & dynamic update");
    end

    // ------------ Tests for dut2 (5x8) ------------
    integer j;
    initial begin
        // Pack as {in4, in3, in2, in1, in0}
        in2 = {
            8'hE4, // index 4
            8'hD3, // index 3
            8'hC2, // index 2
            8'hB1, // index 1
            8'hA0  // index 0
        };

        // Basic checks (use 'd literals)
        sel2 = 3'd0; #1; assert(out2 == 8'hA0) else $display("ERROR[dut2]: sel=0 expected A0, got %h", out2);
        sel2 = 3'd1; #1; assert(out2 == 8'hB1) else $display("ERROR[dut2]: sel=1 expected B1, got %h", out2);
        sel2 = 3'd2; #1; assert(out2 == 8'hC2) else $display("ERROR[dut2]: sel=2 expected C2, got %h", out2);
        sel2 = 3'd3; #1; assert(out2 == 8'hD3) else $display("ERROR[dut2]: sel=3 expected D3, got %h", out2);
        sel2 = 3'd4; #1; assert(out2 == 8'hE4) else $display("ERROR[dut2]: sel=4 expected E4, got %h", out2);

        // Sweep over all valid selects
        for (j = 0; j < N2; j = j + 1) begin
            sel2 = j[2:0]; #1;  // bit-slice loop var to 3 bits
            assert(out2 == in2[j*WIDTH2 +: WIDTH2])
                else $display("ERROR[dut2]: sweep sel=%0d expected %h, got %h",
                              j, in2[j*WIDTH2 +: WIDTH2], out2);
        end

        // Update a lane while selected
        sel2 = 3'd4; #1;
        in2[4*WIDTH2 +: WIDTH2] = 8'h5A; #1;
        assert(out2 == 8'h5A) else $display("ERROR[dut2]: dynamic update lane4 expected 5A, got %h", out2);

        $display("PASS: dut2 (5x8) basic selection & dynamic update");

        $display("FINISHED: MUX testbench complete");
        $finish;
    end

endmodule
