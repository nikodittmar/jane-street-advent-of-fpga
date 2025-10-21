`include "control_sel.vh"

module id_stage (
    input clk,
    input rst,
    input ex_flush,
    input [31:0] id_pc,
    input [31:0] id_bios_inst,
    input [31:0] id_imem_inst,
    input wb_regwen,
    input [31:0] ex_alu, // Forwarded result for jalr target resolution
    input [31:0] mem_alu, // Forwarded result for jalr target resolution
    input [31:0] mem_inst, // MEM instruction for hazard detection
    input [31:0] wb_wdata, // Forwarded result for jalr target resolution
    input [31:0] wb_inst, // WB instruction for hazard detection
    
    output [31:0] id_target, // Branch predictor/target generator output
    output id_target_taken, // Use output of branch predictor/target generator flag
    output ex_br_taken, // Branch predictor branch taken flag
    output [31:0] ex_pc,
    output [31:0] ex_rd1,
    output [31:0] ex_rd2,
    output [31:0] ex_imm,
    output [31:0] ex_inst,
    output id_stall
);
    wire id_reg_rst;
    wire id_reg_we;

    assign id_reg_we = ~id_stall;
    assign id_reg_rst = ex_flush | rst;

    // MARK: InstSel

    wire [31:0] inst;

    wire [$clog2(`INST_SEL_NUM_INPUTS)-1:0] inst_sel = id_pc[30];
    wire [`INST_SEL_NUM_INPUTS*32-1:0] inst_mux_in;

    assign inst_mux_in[`INST_BIOS * 32 +: 32] = id_bios_inst;
    assign inst_mux_in[`INST_IMEM * 32 +: 32] = id_imem_inst;

    mux #(
        .NUM_INPUTS(`INST_SEL_NUM_INPUTS)
    ) inst_mux (
        .in(inst_mux_in),
        .sel(inst_sel),

        .out(inst)
    );

    // MARK: RegFile

    wire [4:0] ra1 = inst[19:15];
    wire [4:0] ra2 = inst[24:20];
    wire [4:0] wa = wb_inst[11:7];
    wire [31:0] rd1;
    wire [31:0] rd2;

    reg_file reg_file (
        .clk(clk),
        .we(wb_regwen),
        .ra1(ra1), .ra2(ra2), .wa(wa),
        .wd(wb_wdata),

        .rd1(rd1), .rd2(rd2)
    );

    // MARK: ImmGen

    wire [2:0] imm_sel;
    wire [31:0] imm;

    imm_gen imm_gen (
        .inst(inst),
        .sel(imm_sel),

        .imm(imm)
    );

    // MARK: TargetGen forwarding

    wire [$clog2(`TGT_GEN_FWD_NUM_INPUTS)-1:0] target_gen_fwd_sel;
    wire [`TGT_GEN_FWD_NUM_INPUTS*32-1:0] target_gen_fwd_in;
    wire [31:0] target_gen_rd1;

    assign target_gen_fwd_in[`TGT_GEN_FWD_NONE * 32 +: 32] = rd1;
    assign target_gen_fwd_in[`TGT_GEN_FWD_EX * 32 +: 32] = ex_alu;
    assign target_gen_fwd_in[`TGT_GEN_FWD_MEM * 32 +: 32] = mem_alu;
    assign target_gen_fwd_in[`TGT_GEN_FWD_WB * 32 +: 32] = wb_wdata;

    mux #(
        .NUM_INPUTS(`TGT_GEN_FWD_NUM_INPUTS)
    ) target_gen_fwd_mux (
        .in(target_gen_fwd_in),
        .sel(target_gen_fwd_sel),

        .out(target_gen_rd1)
    );

    // MARK: TargetGen
    wire [1:0] target_gen_sel;
    wire target_gen_en;

    
    target_gen target_gen (
        .pc(id_pc),
        .sel(target_gen_sel),
        .en(target_gen_en),
        .rd1(target_gen_rd1),
        .imm(imm),
        .target(id_target),
        .target_taken(id_target_taken)
    );

    // MARK: Control

    id_control control (
        .inst(inst),
        .ex_inst(ex_inst),
        .mem_inst(mem_inst),
        .wb_inst(wb_inst),

        .imm_sel(imm_sel),
        .target_gen_sel(target_gen_sel),
        .target_gen_fwd_sel(target_gen_fwd_sel),
        .target_gen_en(target_gen_en),
        .stall(id_stall)
    );

    // MARK: Pipeline registers

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_pc),

        .out(ex_pc)
    );

    pipeline_reg rd1_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(rd1),

        .out(ex_rd1)
    );

    pipeline_reg rd2_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(rd2),

        .out(ex_rd2)
    );

    pipeline_reg imm_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(imm),

        .out(ex_imm)
    );

    pipeline_reg #(
        .RESET_VAL(`NOP)
    ) inst_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(inst),

        .out(ex_inst)
    );
endmodule