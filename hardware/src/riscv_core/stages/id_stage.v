`include "control/control_sel.vh"

module id_stage (
    input clk,
    input [31:0] if_pc,
    input [31:0] if_bios_inst,
    input [31:0] if_imem_inst,
    input [31:0] wb_inst,
    input [31:0] wb_wdata,
    input wb_regwen
    input [31:0] ex_alu, // Forwarded result for branch prediction / jump target resolution
    input [31:0] mem_alu, // Forwarded result for branch prediction / jump target resolution
    input [31:0] wb_wdata, // Forwarded result for branch prediction / jump target resolution
    output [31:0] id_pc,
    output [31:0] id_rd1,
    output [31:0] id_rd2,
    output [31:0] id_imm,
    output [31:0] id_inst
);
    wire id_reg_rst;
    wire id_reg_we;

    // MARK: InstSel

    wire [31:0] inst;

    wire [$clog2(`INST_SEL_NUM_INPUTS)-1:0] inst_sel = if_pc[30];
    wire [`INST_SEL_NUM_INPUTS*32-1:0] inst_mux_in;

    assign inst_mux_in[`INST_BIOS * 32 +: 32] = if_bios_inst;
    assign inst_mux_in[`INST_IMEM * 32 +: 32] = if_imem_inst;

    mux #(
        .NUM_INPUTS(`INST_SEL_NUM_INPUTS)
    ) inst_mux (
        .in(inst_mux_in),
        .sel(inst_sel),

        .out(inst)
    );

    // MARK: RegFile

    wire rf_ra1 = inst[19:15];
    wire rf_ra2 = inst[24:20];
    wire rf_wa = wb_inst[11:7];
    wire [31:0] rd1;
    wire [31:0] rd2;

    reg_file reg_file (
        .clk(clk),
        .we(wb_regwen),
        .ra1(id_rf_ra1), .ra2(id_rf_ra2), .wa(rf_wa),
        .wd(wb_wdata),

        .rd1(rd1), .rd2(rd2)
    );

    // MARK: ImmGen

    wire [2:0] imm_gen_sel;
    wire [31:0] imm;

    imm_gen imm_gen (
        .inst(inst),
        .sel(imm_gen_sel),

        .imm(imm)
    );

    // MARK: Control

    id_control control (
        .inst(inst),
        
        .immsel(imm_gen_sel)
    );

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(if_pc),

        .out(id_pc)
    );

    pipeline_reg rd1_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(rd1),

        .out(id_rd1)
    );

    pipeline_reg rd2_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(rd2),

        .out(id_rd2)
    );

    pipeline_reg imm_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(imm),

        .out(id_imm)
    );

    pipeline_reg inst_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(inst),

        .out(id_inst)
    );
endmodule