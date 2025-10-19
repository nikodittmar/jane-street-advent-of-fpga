`timescale 1ns/1ns

module mem_mask_tb();

    reg [31:0] din;
    reg [3:0] mask;
    reg un;
    wire [31:0] dout;

    mem_mask dut (
        .din(din),
        .mask(mask),
        .un(un),

        .dout(dout)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("mem_mask_tb.fst");
            $dumpvars(0, mem_mask_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // --- BYTE (LB/LBU) ---
        // low byte, unsigned
        mask = 4'b0001; un = 1'b1; din = 32'h0000_0080; #1;
        assert(dout == 32'h0000_0080) else $display("ERROR: LBU low byte zero-ext failed, got %h", dout);

        // low byte, signed (0x80 -> 0xFFFF_FF80)
        mask = 4'b0001; un = 1'b0; din = 32'h0000_0080; #1;
        assert(dout == 32'hFFFF_FF80) else $display("ERROR: LB low byte sign-ext failed, got %h", dout);

        // byte[15:8], unsigned
        mask = 4'b0010; un = 1'b1; din = 32'h0000_8000; #1;
        assert(dout == 32'h0000_0080) else $display("ERROR: LBU byte[15:8] zero-ext failed, got %h", dout);

        // byte[15:8], signed
        mask = 4'b0010; un = 1'b0; din = 32'h0000_8000; #1;
        assert(dout == 32'hFFFF_FF80) else $display("ERROR: LB byte[15:8] sign-ext failed, got %h", dout);

        // byte[23:16], unsigned
        mask = 4'b0100; un = 1'b1; din = 32'h0080_0000; #1;
        assert(dout == 32'h0000_0080) else $display("ERROR: LBU byte[23:16] zero-ext failed, got %h", dout);

        // byte[23:16], signed
        mask = 4'b0100; un = 1'b0; din = 32'h0080_0000; #1;
        assert(dout == 32'hFFFF_FF80) else $display("ERROR: LB byte[23:16] sign-ext failed, got %h", dout);

        // byte[31:24], unsigned
        mask = 4'b1000; un = 1'b1; din = 32'h8000_0000; #1;
        assert(dout == 32'h0000_0080) else $display("ERROR: LBU byte[31:24] zero-ext failed, got %h", dout);

        // byte[31:24], signed
        mask = 4'b1000; un = 1'b0; din = 32'h8000_0000; #1;
        assert(dout == 32'hFFFF_FF80) else $display("ERROR: LB byte[31:24] sign-ext failed, got %h", dout);

        // --- HALFWORD (LH/LHU) ---
        // low halfword, unsigned
        mask = 4'b0011; un = 1'b1; din = 32'h0000_8001; #1;
        assert(dout == 32'h0000_8001) else $display("ERROR: LHU low halfword zero-ext failed, got %h", dout);

        // low halfword, signed (bit15=1)
        mask = 4'b0011; un = 1'b0; din = 32'h0000_8001; #1;
        assert(dout == 32'hFFFF_8001) else $display("ERROR: LH low halfword sign-ext failed, got %h", dout);

        // high halfword, unsigned
        mask = 4'b1100; un = 1'b1; din = 32'h8001_0000; #1;
        assert(dout == 32'h0000_8001) else $display("ERROR: LHU high halfword zero-ext failed, got %h", dout);

        // high halfword, signed (bit31=1)
        mask = 4'b1100; un = 1'b0; din = 32'h8001_0000; #1;
        assert(dout == 32'hFFFF_8001) else $display("ERROR: LH high halfword sign-ext failed, got %h", dout);

        // --- WORD (LW) ---
        mask = 4'b1111; un = 1'bx; din = 32'hDEAD_BEEF; #1;
        assert(dout == 32'hDEAD_BEEF) else $display("ERROR: LW passthrough failed, got %h", dout);

        // another word value
        mask = 4'b1111; un = 1'b0; din = 32'h0123_4567; #1;
        assert(dout == 32'h0123_4567) else $display("ERROR: LW passthrough #2 failed, got %h", dout);

        // --- ILLEGAL / UNKNOWN MASK SHOULD DRIVE X ---
        mask = 4'b0101; un = 1'b0; din = 32'hFFFF_FFFF; #1;
        assert($isunknown(dout)) else $display("ERROR: Illegal mask should drive X, got %h", dout);

        $display("FINISHED: mem_mask testbench complete");
        $finish;
    end
endmodule
