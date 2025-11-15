`timescale 1ns/1ns

module program_counter_tb();

    localparam RESET_PC = 32'h4000_0000;

    reg clk;
    reg rst;
    reg stall;
    reg flush;
    reg in_valid;
    reg [31:0] in;

    wire [31:0] pc;
    reg  [31:0] pc_hold;

    program_counter #(
        .RESET_PC(RESET_PC)
    ) dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .in_valid(in_valid),
        .in(in),
        .out(pc)
    );

    initial clk = 1;
    always #1 clk = ~clk;

    initial begin
        `ifdef IVERILOG
            $dumpfile("program_counter_tb.fst");
            $dumpvars(0, program_counter_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // ----------------------
        // Init + reset
        // ----------------------
        rst      = 1'b1;
        stall    = 1'b0;
        flush    = 1'b0;
        in_valid = 1'b0;
        in       = 32'h0;
        pc_hold  = 32'h0;

        #4;
        rst = 1'b0;

        // ================================================================
        // 0. After reset
        // ================================================================
        @(posedge clk); #0;
        assert(pc == RESET_PC)
            else $display("ERROR: reset PC wrong, got %h", pc);

        // ================================================================
        // 1. Plain incrementing (no stall, no in_valid, no flush)
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment 1 failed, expected %h got %h",
                          pc_hold + 32'd4, pc);

        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment 2 failed, expected %h got %h",
                          pc_hold + 32'd4, pc);

        // ================================================================
        // 2. in_valid (no stall, no flush)
        //     If in_valid goes high, SAME cycle out must equal in
        // ================================================================
        in       = 32'h1111_2222;
        in_valid = 1'b1;

        @(posedge clk); #0;
        assert(pc == 32'h1111_2222)
            else $display("ERROR: in_valid (no stall/flush) did not take effect, got %h", pc);

        // Clear in_valid, then should increment from new PC
        in_valid = 1'b0;
        in       = 32'h0; // don't-care

        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after in_valid failed, expected %h got %h",
                          pc_hold + 32'd4, pc);

        // ================================================================
        // 3. Single-cycle stall
        //     - stall high on cycle N:
        //         out must be the value of PC at cycle N-1
        //     - after stall clears:
        //         out = PC(N-1) + 4 on cycle N+1
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc; // PC at cycle N-1

        stall = 1'b1; // stall will be active at next posedge (cycle N)

        @(posedge clk); #0; // cycle N
        assert(pc == pc_hold)
            else $display("ERROR: single-cycle stall did not hold PC, expected %h got %h",
                          pc_hold, pc);

        stall = 1'b0; // stall clears for next cycle (N+1)

        @(posedge clk); #0; // cycle N+1
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: single-cycle stall did not resume from PC+4, expected %h got %h",
                          pc_hold + 32'd4, pc);

        // ================================================================
        // 4. Multi-cycle stall (no in_valid / flush)
        //     - PC must hold constant for entire stall
        //     - after stall, resume incrementing
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc;

        stall = 1'b1;
        repeat (3) begin
            @(posedge clk); #0;
            assert(pc == pc_hold)
                else $display("ERROR: multi-cycle stall changed PC, expected %h got %h",
                              pc_hold, pc);
        end

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: multi-cycle stall did not resume from PC+4, expected %h got %h",
                          pc_hold + 32'd4, pc);

        // ================================================================
        // 5. in_valid during a SINGLE-cycle stall
        //     - in_valid goes high while stall=1
        //     - PC must hold during stall
        //     - after stall clears, PC must equal 'in'
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc;

        stall    = 1'b1;
        in       = 32'hAAAA_BBBB;
        in_valid = 1'b1;

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: in_valid changed PC during single-cycle stall");

        stall    = 1'b0;
        in_valid = 1'b0;
        in       = 32'h0;

        @(posedge clk); #0;
        assert(pc == 32'hAAAA_BBBB)
            else $display("ERROR: in_valid during single stall not applied after stall, got %h", pc);

        // Increment after that
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after in_valid+stall failed");

        // ================================================================
        // 6. in_valid during a MULTI-cycle stall
        //     - in_valid only high for one cycle while stall=1
        //     - PC must hold for all stall cycles
        //     - after stall clears, PC must equal 'in'
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc;

        stall    = 1'b1;
        in       = 32'hCCCC_DDDD;
        in_valid = 1'b1;

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: in_valid changed PC during first cycle of multi stall");

        // Drop in_valid, keep stalling a few more cycles
        in_valid = 1'b0;
        in       = 32'h0;

        repeat (2) begin
            @(posedge clk); #0;
            assert(pc == pc_hold)
                else $display("ERROR: PC changed during multi stall after in_valid");
        end

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'hCCCC_DDDD)
            else $display("ERROR: in_valid during multi stall not applied after stall, got %h", pc);

        // Resume incrementing
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after multi stall + in_valid failed");

        // ================================================================
        // 7. flush behavior (no stall)
        //     - flush high (with in_valid) should set out= in SAME CYCLE
        // ================================================================
        @(posedge clk); #0;

        flush    = 1'b1;
        in_valid = 1'b1;
        in       = 32'hDEAD_BEEF;

        @(posedge clk); #0;
        assert(pc == 32'hDEAD_BEEF)
            else $display("ERROR: flush (no stall) did not set PC to in, got %h", pc);

        flush    = 1'b0;
        in_valid = 1'b0;
        in       = 32'h0;

        // Increment from flush destination
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after flush failed");

        // ================================================================
        // 8. flush WHILE stall=1
        //     - current stall is ignored
        //     - out must reflect 'in' SAME cycle flush goes high
        // ================================================================
        @(posedge clk); #0;
        pc_hold = pc;

        stall    = 1'b1;

        @(posedge clk); #0; // now in stalled state, PC must hold
        assert(pc == pc_hold)
            else $display("ERROR: PC changed entering stall before flush");

        // Now assert flush + in_valid while stall is still 1
        in       = 32'hF00D_CAFE;
        flush    = 1'b1;
        in_valid = 1'b1;

        @(posedge clk); #0;
        assert(pc == 32'hF00D_CAFE)
            else $display("ERROR: flush did not override stall, got %h", pc);

        // Clear everything
        stall    = 1'b0;
        flush    = 1'b0;
        in_valid = 1'b0;
        in       = 32'h0;

        // Increment from new PC
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after flush+stall failed");

        // ================================================================
        // 9. Stall immediately AFTER a flush
        //     - flush sets PC to 'in'
        //     - next cycle stall holds that value
        // ================================================================
        @(posedge clk); #0;

        flush    = 1'b1;
        in_valid = 1'b1;
        in       = 32'hABCD_1234;

        @(posedge clk); #0;
        assert(pc == 32'hABCD_1234)
            else $display("ERROR: flush before stall did not set PC to in");

        flush    = 1'b0;
        in_valid = 1'b0;
        in       = 32'h0;

        // Now immediately stall
        stall   = 1'b1;
        pc_hold = pc;

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: stall after flush did not hold flushed PC");

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after stall following flush failed");

        // ================================================================
        // 10. in_valid HIGH one cycle BEFORE stall
        //      - in_valid sets PC to 'in'
        //      - stall next cycle holds that value
        //      - after stall, continue incrementing
        // ================================================================
        @(posedge clk); #0;

        in       = 32'h5555_6666;
        in_valid = 1'b1;

        @(posedge clk); #0;
        assert(pc == 32'h5555_6666)
            else $display("ERROR: in_valid before stall: PC not set to in");

        in_valid = 1'b0;
        in       = 32'h0;

        // Now stall one cycle
        stall   = 1'b1;
        pc_hold = pc;

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: stall after in_valid did not hold PC=in");

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4)
            else $display("ERROR: increment after in_valid-then-stall failed");

        // ================================================================
        // 11. Final sanity: a few more plain increments
        // ================================================================
        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4);

        pc_hold = pc;
        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4);

        $display("FINISHED: program_counter testbench complete");
        $finish;
    end

endmodule
