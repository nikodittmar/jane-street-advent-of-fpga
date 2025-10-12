`timescale 1ns/1ns

module branch_comp_tb();

    reg [31:0] d1, d2;
    reg un;
    wire eq, lt;

    branch_comp dut (
        .d1(d1),
        .d2(d2),
        .un(un),

        .eq(eq),
        .lt(lt)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("branch_comp_tb.fst");
            $dumpvars(0, branch_comp_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // init
        d1 = 32'd0; d2 = 32'd0; un = 1'b0; #1;

        // --- Equality (independent of 'un') ---
        d1 = 32'h0000_0000; d2 = 32'h0000_0000; un = 1'b0; #1;
        assert(eq == 1'b1) else $display("ERROR: eq: 0 == 0 (signed), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 0 < 0 (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b1) else $display("ERROR: eq: 0 == 0 (unsigned), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 0 < 0 (unsigned), got %b", lt);

        d1 = 32'hFFFF_FFFF; d2 = 32'hFFFF_FFFF; un = 1'b0; #1;
        assert(eq == 1'b1) else $display("ERROR: eq: -1 == -1 (signed), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: -1 < -1 (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b1) else $display("ERROR: eq: 0xFFFF_FFFF == 0xFFFF_FFFF (unsigned), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: ... (unsigned), got %b", lt);

        // --- Simple ordered positives (same under signed/unsigned) ---
        d1 = 32'd2; d2 = 32'd5; un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 2 == 5 (signed), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: 2 < 5 (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 2 == 5 (unsigned), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: 2 < 5 (unsigned), got %b", lt);

        d1 = 32'd5; d2 = 32'd2; un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 5 == 2 (signed), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 5 < 2 (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 5 == 2 (unsigned), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 5 < 2 (unsigned), got %b", lt);

        // --- Signed vs unsigned divergence: -1 vs 1 ---
        d1 = 32'hFFFF_FFFF; // -1 (signed)
        d2 = 32'h0000_0001; // 1
        un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: -1 == 1 (signed), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: -1 < 1 (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 0xFFFF_FFFF == 1 (unsigned), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 0xFFFF_FFFF < 1 (unsigned), got %b", lt);

        // --- Signed vs unsigned divergence: INT_MIN vs INT_MAX ---
        d1 = 32'h8000_0000; // -2^31 signed, 2^31 unsigned
        d2 = 32'h7FFF_FFFF; //  2^31-1
        un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: INT_MIN == INT_MAX (signed), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: INT_MIN < INT_MAX (signed), got %b", lt);
        un = 1'b1; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 0x8000_0000 == 0x7FFF_FFFF (unsigned), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 0x8000_0000 < 0x7FFF_FFFF (unsigned), got %b", lt);

        // --- Another divergence: 0 vs INT_MIN ---
        d1 = 32'h0000_0000;
        d2 = 32'h8000_0000;
        un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 0 == INT_MIN (signed), got %b", eq);
        assert(lt == 1'b0) else $display("ERROR: lt: 0 < INT_MIN (signed), got %b", lt); // 0 > -2^31
        un = 1'b1; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: 0 == 0x8000_0000 (unsigned), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: 0 < 0x8000_0000 (unsigned), got %b", lt);

        // --- Random-ish signed case: -5 vs -3 ---
        d1 = 32'hFFFF_FFFB; // -5
        d2 = 32'hFFFF_FFFD; // -3
        un = 1'b0; #1;
        assert(eq == 1'b0) else $display("ERROR: eq: -5 == -3 (signed), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: -5 < -3 (signed), got %b", lt);
        un = 1'b1; #1;
        // As unsigned, 0x...FFFB (4294967291) < 0x...FFFD (4294967293) -> true
        assert(eq == 1'b0) else $display("ERROR: eq: 0xFFFB == 0xFFFD (unsigned), got %b", eq);
        assert(lt == 1'b1) else $display("ERROR: lt: 0xFFFB < 0xFFFD (unsigned), got %b", lt);

        $display("FINISHED: branch_comp testbench complete");
        $finish;
    end
endmodule
