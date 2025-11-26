`include "control_sel.vh"
`include "opcode.vh"

module id_stage (
    input clk,
    input rst,

    input [31:0] id_pc,
    input [31:0] id_bios_inst,
    input [31:0] id_imem_inst,
    input [1:0] id_inst_sel,

    input [31:0] ex_fp_inst,
    input ex_fpu_busy,

    input [31:0] wb_inst,
    input [31:0] wb_fp_inst,
    input [31:0] wb_wdata,
    input [31:0] wb_fp_wdata,
    input wb_flush,
    input wb_regwen,
    input wb_fp_regwen,
    
    output [31:0] ex_pc,
    output [31:0] ex_rd1,
    output [31:0] ex_rd2,
    output [31:0] ex_fd1,
    output [31:0] ex_fd2,
    output [31:0] ex_fd3,
    output [31:0] ex_imm,
    output [31:0] ex_inst,
    output [31:0] ex_target, // Branch predictor/target generator output
    output ex_target_taken, // Use output of branch predictor/target generator flag
    output ex_br_taken, // Branch predictor branch taken flag
    output ex_fpu_valid,

    output id_stall
);
    wire id_ex_stall;
    wire stall;

    wire id_reg_rst = !id_ex_stall && (stall || wb_flush || rst);
    wire id_reg_we = !stall && !id_ex_stall;

    // MARK: InstSel

    wire [$clog2(`INST_SEL_NUM_INPUTS)-1:0] inst_sel = ex_target_taken ? `INST_NOP : id_inst_sel;
    wire [`INST_SEL_NUM_INPUTS*32-1:0] inst_mux_in;
    wire [31:0] id_inst;

    assign inst_mux_in[`INST_BIOS * 32 +: 32] = id_bios_inst;
    assign inst_mux_in[`INST_IMEM * 32 +: 32] = id_imem_inst;
    assign inst_mux_in[`INST_NOP * 32 +: 32] = `NOP;

    mux #(
        .NUM_INPUTS(`INST_SEL_NUM_INPUTS)
    ) inst_mux (
        .in(inst_mux_in),
        .sel(inst_sel),

        .out(id_inst)
    );

    // MARK: RegFile

    wire [4:0] ra1 = id_inst[19:15];
    wire [4:0] ra2 = id_inst[24:20];
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

    // MARK: FP RegFile

    wire [4:0] ra3 = id_inst[31:27];
    wire [4:0] fwa = wb_inst[6:0] == `OPC_FP_LOAD ? wb_inst[11:7] : wb_fp_inst[11:7];
    wire [31:0] fd1;
    wire [31:0] fd2;
    wire [31:0] fd3;

    fp_reg_file fp_reg_file (
        .clk(clk),
        .we(wb_fp_regwen),
        .ra1(ra1), .ra2(ra2), .ra3(ra3), .wa(fwa),
        .wd(wb_fp_wdata),

        .rd1(fd1), .rd2(fd2), .rd3(fd3)
    );

    // MARK: ImmGen

    wire [2:0] imm_sel;
    wire [31:0] imm;

    imm_gen imm_gen (
        .inst(id_inst),
        .sel(imm_sel),

        .imm(imm)
    );

    // MARK: TargetGen
    
    wire target_gen_sel;
    wire target_gen_en;
    wire br_taken;

    wire [31:0] target;
    wire target_taken;
    
    target_gen target_gen (
        .pc(id_pc),
        .sel(target_gen_sel),
        .en(target_gen_en),
        .imm(imm),

        .target(target),
        .target_taken(target_taken),
        .branch_taken(br_taken)
    );

    // MARK: Control
    assign id_stall = id_ex_stall || stall;
    wire fpu_valid;

    id_control control (
        .inst(id_inst),
        .ex_inst(ex_inst),
        .ex_fp_inst(ex_fp_inst),
        .fpu_busy(ex_fpu_busy),
    
        .imm_sel(imm_sel),
        .target_gen_sel(target_gen_sel),
        .target_gen_en(target_gen_en),
        .stall(stall),
        .id_ex_stall(id_ex_stall),
        .fpu_valid(fpu_valid)
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

    pipeline_reg fd1_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(fd1),

        .out(ex_fd1)
    );

    pipeline_reg fd2_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(fd2),

        .out(ex_fd2)
    );

    pipeline_reg fd3_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(fd3),

        .out(ex_fd3)
    );

    pipeline_reg imm_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(imm),

        .out(ex_imm)
    );

    pipeline_reg #(
        .WIDTH(1)
    ) br_taken_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(br_taken),

        .out(ex_br_taken)
    );

    pipeline_reg #(
        .RESET_VAL(`NOP)
    ) inst_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_inst),

        .out(ex_inst)
    );

    pipeline_reg target_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(target),

        .out(ex_target)
    );

    pipeline_reg #(
        .WIDTH(1)
    ) target_taken_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(target_taken),

        .out(ex_target_taken)
    );

    pipeline_reg #(
        .WIDTH(1)
    ) fpu_valid_reg (
        .clk(clk),
        .rst(1'b0),
        .we(1'b1),
        .in(fpu_valid),

        .out(ex_fpu_valid)
    );

endmodule