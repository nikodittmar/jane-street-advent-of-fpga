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
        expect_eq(eq, 1'b1, "eq: 0 == 0 (signed)");  expect_eq(lt, 1'b0, "lt: 0 < 0 (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b1, "eq: 0 == 0 (unsigned)"); expect_eq(lt, 1'b0, "lt: 0 < 0 (unsigned)");

        d1 = 32'hFFFF_FFFF; d2 = 32'hFFFF_FFFF; un = 1'b0; #1;
        expect_eq(eq, 1'b1, "eq: -1 == -1 (signed)"); expect_eq(lt, 1'b0, "lt: -1 < -1 (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b1, "eq: 0xFFFF_FFFF == 0xFFFF_FFFF (unsigned)"); expect_eq(lt, 1'b0, "lt: ... (unsigned)");

        // --- Simple ordered positives (same under signed/unsigned) ---
        d1 = 32'd2; d2 = 32'd5; un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: 2 == 5 (signed)");   expect_eq(lt, 1'b1, "lt: 2 < 5 (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b0, "eq: 2 == 5 (unsigned)"); expect_eq(lt, 1'b1, "lt: 2 < 5 (unsigned)");

        d1 = 32'd5; d2 = 32'd2; un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: 5 == 2 (signed)");   expect_eq(lt, 1'b0, "lt: 5 < 2 (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b0, "eq: 5 == 2 (unsigned)"); expect_eq(lt, 1'b0, "lt: 5 < 2 (unsigned)");

        // --- Signed vs unsigned divergence: -1 vs 1 ---
        d1 = 32'hFFFF_FFFF; // -1 (signed)
        d2 = 32'h0000_0001; // 1
        un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: -1 == 1 (signed)");  expect_eq(lt, 1'b1, "lt: -1 < 1 (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b0, "eq: 0xFFFF_FFFF == 1 (unsigned)"); expect_eq(lt, 1'b0, "lt: 0xFFFF_FFFF < 1 (unsigned)");

        // --- Signed vs unsigned divergence: INT_MIN vs INT_MAX ---
        d1 = 32'h8000_0000; // -2^31 signed, 2^31 unsigned
        d2 = 32'h7FFF_FFFF; //  2^31-1
        un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: INT_MIN == INT_MAX (signed)"); expect_eq(lt, 1'b1, "lt: INT_MIN < INT_MAX (signed)");
        un = 1'b1; #1;
        expect_eq(eq, 1'b0, "eq: 0x8000_0000 == 0x7FFF_FFFF (unsigned)"); expect_eq(lt, 1'b0, "lt: 0x8000_0000 < 0x7FFF_FFFF (unsigned)");

        // --- Another divergence: 0 vs INT_MIN ---
        d1 = 32'h0000_0000;
        d2 = 32'h8000_0000;
        un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: 0 == INT_MIN (signed)");  expect_eq(lt, 1'b0, "lt: 0 < INT_MIN (signed)"); // 0 > -2^31
        un = 1'b1; #1;
        expect_eq(eq, 1'b0, "eq: 0 == 0x8000_0000 (unsigned)"); expect_eq(lt, 1'b1, "lt: 0 < 0x8000_0000 (unsigned)");

        // --- Random-ish signed case: -5 vs -3 (signed true, unsigned depends on magnitude) ---
        d1 = 32'hFFFF_FFFB; // -5
        d2 = 32'hFFFF_FFFD; // -3
        un = 1'b0; #1;
        expect_eq(eq, 1'b0, "eq: -5 == -3 (signed)"); expect_eq(lt, 1'b1, "lt: -5 < -3 (signed)");
        un = 1'b1; #1;
        // As unsigned, 0x...FFFB (4294967291) < 0x...FFFD (4294967293) -> true
        expect_eq(eq, 1'b0, "eq: 0xFFFB == 0xFFFD (unsigned)"); expect_eq(lt, 1'b1, "lt: 0xFFFB < 0xFFFD (unsigned)");

        $display("PASS: All branch_comp tests passed");
        $finish;
    end
endmodule