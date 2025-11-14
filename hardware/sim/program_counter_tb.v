`timescale 1ns/1ns

module program_counter_tb();

    localparam RESET_PC = 32'h4000_0000;

    reg clk;
    reg rst;
    reg stall;
    reg target_taken;
    reg redirect_taken;
    reg [31:0] target;
    reg [31:0] redirect;
    wire [31:0] pc;

    reg [31:0] pc_hold;

    program_counter #(
        .RESET_PC(RESET_PC)
    ) dut (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .target_taken(target_taken),
        .target(target),
        .redirect_taken(redirect_taken),
        .redirect(redirect),
        .pc_out(pc)
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
        
        // init
        rst            = 1'b1;
        stall          = 1'b0;
        target_taken   = 1'b0;
        redirect_taken = 1'b0;
        target         = 32'h0;
        redirect       = 32'h0;
        pc_hold        = 32'h0;

        #4;

        // Deassert reset
        rst = 1'b0;

        // --------------------------------------------------------------------
        // 1. Normal incrementing
        // --------------------------------------------------------------------
        @(posedge clk); #0;
        assert(pc == RESET_PC);

        @(posedge clk); #0;
        assert(pc == RESET_PC + 32'd4);

        @(posedge clk); #0;
        assert(pc == RESET_PC + 32'd8);

        // --------------------------------------------------------------------
        // 2. target_taken changes PC on SAME cycle
        // --------------------------------------------------------------------
        target         = 32'h1234_5678;
        target_taken   = 1'b1;
        stall          = 1'b0;
        redirect_taken = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h1234_5678);

        target_taken = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h1234_5678 + 32'd4);

        // --------------------------------------------------------------------
        // 3. redirect_taken changes PC on SAME cycle
        // --------------------------------------------------------------------
        redirect       = 32'hDEAD_BEEF;
        redirect_taken = 1'b1;
        stall          = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'hDEAD_BEEF);

        redirect_taken = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'hDEAD_BEEF + 32'd4);

        // ====================================================================
        // 4. redirect/target asserted WHILE stall=1 SHOULD NOT APPLY YET
        //    They must apply ONLY AFTER stall drops.
        // ====================================================================

        // 4a) target_taken during stall -> PC must NOT change yet
        stall        = 1'b1;
        target       = 32'hCAFEBABE;
        target_taken = 1'b1;

        pc_hold = pc; // PC should remain unchanged during stall

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: target_taken during stall applied too early");

        // Now release stall -> target redirect should finally apply
        stall        = 1'b0;
        target_taken = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'hCAFEBABE)
            else $display("ERROR: target redirect did NOT occur after stall cleared");

        // 4b) redirect_taken during stall -> same logic
        stall          = 1'b1;
        redirect       = 32'h0BAD_F00D;
        redirect_taken = 1'b1;

        pc_hold = pc;

        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: redirect_taken during stall applied too early");

        stall          = 1'b0;
        redirect_taken = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h0BAD_F00D)
            else $display("ERROR: redirect did NOT occur after stall cleared");

        // --------------------------------------------------------------------
        // 5. Single-cycle stall
        // --------------------------------------------------------------------
        @(posedge clk); #0;
        pc_hold = pc;

        stall = 1'b1;

        @(posedge clk); #0;
        assert(pc == pc_hold);

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4);

        // --------------------------------------------------------------------
        // 6. Multi-cycle stall AFTER redirect
        // --------------------------------------------------------------------
        redirect       = 32'h1000_0000;
        redirect_taken = 1'b1;
        stall          = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h1000_0000);

        redirect_taken = 1'b0;
        stall          = 1'b1;

        repeat (3) begin
            @(posedge clk); #0;
            assert(pc == 32'h1000_0000);
        end

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h1000_0000 + 32'd4);

        // --------------------------------------------------------------------
        // 7. Multi-cycle stall normal
        // --------------------------------------------------------------------
        @(posedge clk); #0;
        pc_hold = pc;

        stall = 1'b1;

        repeat (3) begin
            @(posedge clk); #0;
            assert(pc == pc_hold);
        end

        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == pc_hold + 32'd4);

        // --------------------------------------------------------------------
        // 8. Multicycle stall with redirect on the FIRST stall cycle
        //     - redirect_taken asserted only on first stalled cycle
        //     - PC must hold during all stall cycles
        //     - When stall drops, PC must jump to redirect
        // --------------------------------------------------------------------
        @(posedge clk); #0;
        pc_hold        = pc;              // baseline before stall+redirect
        redirect       = 32'h2000_0000;
        stall          = 1'b1;
        redirect_taken = 1'b1;

        // First stall cycle: redirect_taken is high, but PC must still hold
        @(posedge clk); #0;
        assert(pc == pc_hold)
            else $display("ERROR: test8: redirect applied during stall");

        // Subsequent stall cycles: redirect_taken is now low, PC still holds
        redirect_taken = 1'b0;

        repeat (2) begin
            @(posedge clk); #0;
            assert(pc == pc_hold)
                else $display("ERROR: test8: PC changed during multicycle stall");
        end

        // Drop stall: redirect should now finally be applied
        stall = 1'b0;

        @(posedge clk); #0;
        assert(pc == 32'h2000_0000)
            else $display("ERROR: test8: redirect NOT applied after multicycle stall");

        // And then it should resume incrementing from redirect
        @(posedge clk); #0;
        assert(pc == 32'h2000_0000 + 32'd4)
            else $display("ERROR: test8: PC did not increment after redirect");

        $display("FINISHED: program_counter testbench complete");
        $finish;
    end

endmodule
