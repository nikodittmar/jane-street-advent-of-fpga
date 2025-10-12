`timescale 1ns/1ns

`define CLK_PERIOD 8

module reg_file_tb();

    reg clk = 1'b0;

    always #(`CLK_PERIOD/2) clk <= ~clk;

    reg we;
    reg [4:0] ra1, ra2, wa;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;

    reg_file dut (
        .clk(clk),
        .we(we),
        .ra1(ra1),
        .ra2(ra2),
        .wa(wa),
        .wd(wd),

        .rd1(rd1),
        .rd2(rd2)
    );

    // Write helper
    task write_reg;
        input [4:0] r;
        input [31:0] val;
        begin
            @(posedge clk);
            #1;
            we = 1'b1;
            wa = r;
            wd = val;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

    integer i;
    initial begin
        `ifdef IVERILOG
            $dumpfile("reg_file_tb.fst");
            $dumpvars(0, reg_file_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // Initialize inputs
        we = 1'b0;
        ra1 = 5'b0;
        ra2 = 5'b0;
        wa  = 5'b0;
        wd  = 32'b0;
        @(posedge clk);

        // 1) x0 behavior
        ra1 = 5'd0; ra2 = 5'd0; #1;
        assert(rd1 == 32'h0000_0000) else $display("ERROR: x0 read port 1 expected 0, got %h", rd1);
        assert(rd2 == 32'h0000_0000) else $display("ERROR: x0 read port 2 expected 0, got %h", rd2);

        write_reg(5'd0, 32'hDEAD_BEEF); // ignored
        ra1 = 5'd0; #1;
        assert(rd1 == 32'h0000_0000) else $display("ERROR: x0 still zero after write attempt expected 0, got %h", rd1);

        // 2) Basic writes/reads
        for (i = 1; i <= 31; i = i + 1) begin
            write_reg(i[4:0], 32'h4141_4140 + i); // 'A' base + i
            ra1 = i[4:0]; ra2 = i[4:0]; #1;
            assert(rd1 == (32'h4141_4140 + i))
                else $display("ERROR: basic read r%0d p1 expected %h, got %h", i, (32'h4141_4140 + i), rd1);
            assert(rd2 == (32'h4141_4140 + i))
                else $display("ERROR: basic read r%0d p2 expected %h, got %h", i, (32'h4141_4140 + i), rd2);
        end

        // 3) Rewrites
        write_reg(5'd12, 32'h1234_5678);
        ra1 = 5'd12; #1;
        assert(rd1 == 32'h1234_5678) else $display("ERROR: rewrite r12 A expected %h, got %h", 32'h1234_5678, rd1);
        write_reg(5'd12, 32'hCAFE_BABE);
        #1;
        assert(rd1 == 32'hCAFE_BABE) else $display("ERROR: rewrite r12 B expected %h, got %h", 32'hCAFE_BABE, rd1);

        // 4) Dual-port different regs
        ra1 = 5'd3; ra2 = 5'd29; #1;
        assert(rd1 == (32'h4141_4140 + 3))
            else $display("ERROR: dual-port r3 expected %h, got %h", (32'h4141_4140 + 3), rd1);
        assert(rd2 == (32'h4141_4140 + 29))
            else $display("ERROR: dual-port r29 expected %h, got %h", (32'h4141_4140 + 29), rd2);

        // 5) Same-cycle read/write semantics (no bypass expected)
        // Prepare r5 with known old value
        write_reg(5'd5, 32'hAAAA_5555);
        // Drive new write and read same cycle BEFORE edge -> expect old value
        we = 1; wa = 5'd5; wd = 32'h1111_2222; ra1 = 5'd5; #1;
        assert(rd1 == 32'hAAAA_5555)
            else $display("ERROR: same-cycle pre-edge returns OLD expected %h, got %h", 32'hAAAA_5555, rd1);
        @(posedge clk); #1;
        assert(rd1 == 32'h1111_2222)
            else $display("ERROR: post-edge returns NEW expected %h, got %h", 32'h1111_2222, rd1);
        we = 0;

        // 6) Back-to-back writes
        we = 1; wa = 5'd7; wd = 32'h0000_0001; @(posedge clk); #1;
        wd = 32'h0000_0002;                  @(posedge clk); #1; we = 0;
        ra1 = 5'd7; #1;
        assert(rd1 == 32'h0000_0002)
            else $display("ERROR: back-to-back final expected %h, got %h", 32'h0000_0002, rd1);

        // 7) Write-enable gating
        wa = 5'd9; wd = 32'hFACE_FACE; we = 0; @(posedge clk); #1;
        ra1 = 5'd9; #1;
        assert(rd1 == (32'h4141_4140 + 9))
            else $display("ERROR: no write when we=0 expected %h, got %h", (32'h4141_4140 + 9), rd1);

        $display("FINISHED: reg_file testbench complete");
        $finish;
    end

endmodule
