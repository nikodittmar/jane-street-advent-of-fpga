`timescale 1ns/1ns
`include "../src/riscv_core/control_sel.vh"

module mem_pack_tb();

    reg [31:0] in;
    reg [1:0] offset;
    reg [1:0] size;

    wire [31:0] out;
    wire [3:0] we;

    mem_pack dut (
        .in(in),
        .offset(offset),
        .size(size),
        
        .out(out),
        .we(we)
    );

    initial begin
        `ifdef IVERILOG
            $dumpfile("mem_pack_tb.fst");
            $dumpvars(0, mem_pack_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // ========== BYTE (SB) ==========
        // offset 00 -> byte[7:0]
        size = `MEM_SIZE_BYTE; offset = 2'b00; in = 32'h0000_00A5; #1;
        assert(we == 4'b0001) else $display("ERROR: SB off=00 WE expected 0001, got %b", we);
        assert(out[7:0] == 8'hA5) else $display("ERROR: SB off=00 out[7:0] expected A5, got %h", out[7:0]);

        // offset 01 -> byte[15:8]
        size = `MEM_SIZE_BYTE; offset = 2'b01; in = 32'h0000_00BC; #1;
        assert(we == 4'b0010) else $display("ERROR: SB off=01 WE expected 0010, got %b", we);
        assert(out[15:8] == 8'hBC) else $display("ERROR: SB off=01 out[15:8] expected BC, got %h", out[15:8]);

        // offset 10 -> byte[23:16]
        size = `MEM_SIZE_BYTE; offset = 2'b10; in = 32'h0000_00D7; #1;
        assert(we == 4'b0100) else $display("ERROR: SB off=10 WE expected 0100, got %b", we);
        assert(out[23:16] == 8'hD7) else $display("ERROR: SB off=10 out[23:16] expected D7, got %h", out[23:16]);

        // offset 11 -> byte[31:24]
        size = `MEM_SIZE_BYTE; offset = 2'b11; in = 32'h0000_00EE; #1;
        assert(we == 4'b1000) else $display("ERROR: SB off=11 WE expected 1000, got %b", we);
        assert(out[31:24] == 8'hEE) else $display("ERROR: SB off=11 out[31:24] expected EE, got %h", out[31:24]);

        // ========== HALFWORD (SH) ==========
        // offset 00 -> half[15:0]
        size = `MEM_SIZE_HALF; offset = 2'b00; in = 32'h0000_ABCD; #1;
        assert(we == 4'b0011) else $display("ERROR: SH off=00 WE expected 0011, got %b", we);
        assert(out[15:0] == 16'hABCD) else $display("ERROR: SH off=00 out[15:0] expected ABCD, got %h", out[15:0]);

        // offset 10 -> half[31:16]
        size = `MEM_SIZE_HALF; offset = 2'b10; in = 32'h0000_1357; #1;
        assert(we == 4'b1100) else $display("ERROR: SH off=10 WE expected 1100, got %b", we);
        assert(out[31:16] == 16'h1357) else $display("ERROR: SH off=10 out[31:16] expected 1357, got %h", out[31:16]);

        // illegal halfword offsets (01, 11) per your RTL (no case matches)
        size = `MEM_SIZE_HALF; offset = 2'b01; in = 32'h0000_9999; #1;
        assert(we == 4'b0000) else $display("ERROR: SH off=01 illegal: WE expected 0000, got %b", we);

        size = `MEM_SIZE_HALF; offset = 2'b11; in = 32'h0000_7777; #1;
        assert(we == 4'b0000) else $display("ERROR: SH off=11 illegal: WE expected 0000, got %b", we);

        // ========== WORD (SW) ==========
        size = `MEM_SIZE_WORD; offset = 2'b00; in = 32'hDEAD_BEEF; #1;
        assert(we == 4'b1111) else $display("ERROR: SW WE expected 1111, got %b", we);
        assert(out == 32'hDEAD_BEEF) else $display("ERROR: SW out expected DEAD_BEEF, got %h", out);

        // offset is ignored for word in your RTL; verify once more
        size = `MEM_SIZE_WORD; offset = 2'b10; in = 32'h0123_4567; #1;
        assert(we == 4'b1111) else $display("ERROR: SW(off ignored) WE expected 1111, got %b", we);
        assert(out == 32'h0123_4567) else $display("ERROR: SW(off ignored) out expected 0123_4567, got %h", out);

        $display("FINISHED: mem_pack testbench complete");
        $finish;
    end

endmodule
