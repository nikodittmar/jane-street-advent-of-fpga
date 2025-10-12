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

    // Helpers
    task write_reg;
        input [4:0] r;
        input [31:0] val;
        begin
            @(posedge clk);
            #1
            we = 1'b1; 
            wa = r; 
            wd = val;
            @(posedge clk);
            #1;
            we = 1'b0;
        end
    endtask

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
        wa = 5'b0;
        wd = 32'b0;
        @(posedge clk);

        // 1) x0 behavior
        ra1 = 5'd0; ra2 = 5'd0; #1;
        expect_eq(rd1, 32'h0, "x0 read port 1");
        expect_eq(rd2, 32'h0, "x0 read port 2");

        write_reg(5'd0, 32'hDEADBEEF); // ignored
        ra1 = 5'd0; #1;
        expect_eq(rd1, 32'h0, "x0 still zero after write attempt");

        // 2) Basic writes/reads
        for (i=1; i<=31; i=i+1) begin
            write_reg(i[4:0], 32'h41414140 + i); // 'A' base + i
            ra1 = i[4:0]; ra2 = i[4:0]; #1;
            expect_eq(rd1, 32'h41414140 + i, $sformatf("basic read r%0d p1", i));
            expect_eq(rd2, 32'h41414140 + i, $sformatf("basic read r%0d p2", i));
        end

        // 3) Rewrites
        write_reg(5'd12, 32'h12345678);
        ra1 = 5'd12; #1; expect_eq(rd1, 32'h12345678, "rewrite r12 A");
        write_reg(5'd12, 32'hCAFEBABE);
        #1; expect_eq(rd1, 32'hCAFEBABE, "rewrite r12 B");

        // 4) Dual-port different regs
        ra1 = 5'd3; ra2 = 5'd29; #1;
        expect_eq(rd1, 32'h41414140 + 3,  "dual-port r3");
        expect_eq(rd2, 32'h41414140 + 29, "dual-port r29");

        // 5) Same-cycle read/write semantics (no bypass expected)
        // Prepare r5 with known old value
        write_reg(5'd5, 32'hAAAA5555);
        // Drive new write and read same cycle BEFORE edge -> expect old value
        we = 1; wa = 5'd5; wd = 32'h11112222; ra1 = 5'd5; #1;
        expect_eq(rd1, 32'hAAAA5555, "same-cycle pre-edge returns OLD");
        @(posedge clk); #1;
        expect_eq(rd1, 32'h11112222, "post-edge returns NEW");
        we = 0;

        // 6) Back-to-back writes
        we=1; wa=5'd7; wd=32'h0000_0001; @(posedge clk); #1;
        wd=32'h0000_0002;               @(posedge clk); #1; we=0;
        ra1=5'd7; #1; expect_eq(rd1, 32'h0000_0002, "back-to-back final");

        // 7) Write-enable gating
        wa=5'd9; wd=32'hFACEFACE; we=0; @(posedge clk); #1;
        ra1=5'd9; #1; expect_eq(rd1, 32'h41414149, "no write when we=0");

        $display("PASS: All reg_file tests passed");
        $finish;
    end

endmodule