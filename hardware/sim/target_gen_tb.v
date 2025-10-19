`include "../src/riscv_core/control_sel.vh"
`timescale 1ns/1ns

module target_gen_tb();

    reg [31:0] pc;
    reg [1:0] sel;
    reg en;
    reg [31:0] rd1;
    reg [31:0] imm;

    wire [31:0] target;
    wire target_taken;

    // DUT
    target_gen dut (
        .pc(pc),
        .sel(sel),
        .en(en),
        .rd1(rd1),
        .imm(imm),

        .target(target),
        .target_taken(target_taken)
    );

    
    initial begin
        `ifdef IVERILOG
            $dumpfile("target_gen_tb.fst");
            $dumpvars(0, target_gen_tb);
        `endif
        `ifndef IVERILOG
            $vcdpluson;
        `endif

        // Defaults
        pc  = 32'h0;
        sel = 2'b00;
        en  = 1'b0;
        rd1 = 32'h0;
        imm = 32'h0;
        #1;

        // --- EN=0 should force zeros regardless of sel ---
        en = 1'b0; sel = `TGT_GEN_JAL; pc = 32'h0000_1000; imm = 32'd12; #1;
        assert(target == 32'h0 && target_taken == 1'b0)
            else $display("ERROR: en=0 gating failed (JAL) target=%h taken=%0d", target, target_taken);

        // =========================
        // JAL: target = pc + signed(imm), always taken
        // =========================
        en = 1'b1; sel = `TGT_GEN_JAL; pc = 32'h0000_1000; imm = 32'd12; #1;
        assert(target == 32'h0000_100C && target_taken == 1'b1)
            else $display("ERROR: JAL +12 expected 0x0000100C, got %h taken=%0d", target, target_taken);

        // JAL negative immediate (signed)
        sel = `TGT_GEN_JAL; pc = 32'h0000_1000; imm = 32'hFFFF_FFF0; #1; // -16
        assert(target == 32'h0000_0FF0 && target_taken == 1'b1)
            else $display("ERROR: JAL -16 expected 0x00000FF0, got %h taken=%0d", target, target_taken);

        // Wraparound case
        sel = `TGT_GEN_JAL; pc = 32'hFFFF_FFFC; imm = 32'd8; #1;
        assert(target == 32'h0000_0004 && target_taken == 1'b1)
            else $display("ERROR: JAL wraparound expected 0x00000004, got %h taken=%0d", target, target_taken);

        // =========================
        // JALR: target = pc + signed(rd1), always taken (per your module)
        // =========================
        sel = `TGT_GEN_JALR; pc = 32'h0000_2000; rd1 = 32'd32; #1;
        assert(target == 32'h0000_2020 && target_taken == 1'b1)
            else $display("ERROR: JALR pc+32 expected 0x00002020, got %h taken=%0d", target, target_taken);

        // Negative rd1
        sel = `TGT_GEN_JALR; pc = 32'h0000_2000; rd1 = 32'hFFFF_FFE0; #1; // -32
        assert(target == 32'h0000_1FE0 && target_taken == 1'b1)
            else $display("ERROR: JALR pc-32 expected 0x00001FE0, got %h taken=%0d", target, target_taken);

        // Large add wraparound
        sel = `TGT_GEN_JALR; pc = 32'hFFFF_FFF0; rd1 = 32'd64; #1;
        assert(target == 32'h0000_0030 && target_taken == 1'b1)
            else $display("ERROR: JALR wraparound expected 0x00000030, got %h taken=%0d", target, target_taken);

        // =========================
        // BR (Forward/Backward): take only if imm < 0
        // =========================

        // Negative imm -> taken
        sel = `TGT_GEN_BR; pc = 32'h0000_3000; imm = 32'hFFFF_FFFC; #1; // -4
        assert(target == 32'h0000_2FFC && target_taken == 1'b1)
            else $display("ERROR: BR -4 expected taken to 0x00002FFC, got %h taken=%0d", target, target_taken);

        // Positive imm -> not taken (outputs zeroed by TB's pre-case init)
        sel = `TGT_GEN_BR; pc = 32'h0000_3000; imm = 32'd64; #1;
        assert(target == 32'h0000_0000 && target_taken == 1'b0)
            else $display("ERROR: BR +64 expected not taken/zero, got %h taken=%0d", target, target_taken);

        // Zero imm -> not taken (since !(imm<0))
        sel = `TGT_GEN_BR; pc = 32'h0000_3000; imm = 32'd0; #1;
        assert(target == 32'h0000_0000 && target_taken == 1'b0)
            else $display("ERROR: BR 0 expected not taken/zero, got %h taken=%0d", target, target_taken);

        // Most negative imm -> taken (wraparound check)
        sel = `TGT_GEN_BR; pc = 32'h0000_0008; imm = 32'h8000_0000; #1; // -2^31
        assert(target == 32'h8000_0008 && target_taken == 1'b1)
            else $display("ERROR: BR INT_MIN expected target 0x80000008, got %h taken=%0d", target, target_taken);

        // =========================
        // Invalid sel with en=1 -> remains zeros
        // =========================
        sel = 2'b11; pc = 32'h1234_5678; imm = 32'd4; rd1 = 32'd4; #1;
        assert(target == 32'h0 && target_taken == 1'b0)
            else $display("ERROR: invalid sel expected zeros, got target=%h taken=%0d", target, target_taken);

        // =========================
        // Drive en back to 0 -> zeros again
        // =========================
        en = 1'b0; sel = `TGT_GEN_BR; pc = 32'h0000_4000; imm = 32'hFFFF_FFFC; #1;
        assert(target == 32'h0 && target_taken == 1'b0)
            else $display("ERROR: en=0 gating (after activity) expected zeros, got %h taken=%0d", target, target_taken);

        $display("FINISHED: target_gen (Fwd/Back BR pred) testbench complete");
        $finish;
    end
endmodule