`include "control_sel.vh"
`include "opcode.vh"

module id_stage (
    input clk,
    input rst,

    input [31:0] id_pc,
    input [31:0] id_bios_inst,
    input [31:0] id_imem_inst,
    input id_target_taken,

    input [31:0] ex_fp_inst,
    input ex_fpu_busy,
    input ex_flush,

    input [31:0] wb_inst,
    input [31:0] wb_fp_inst,
    input [31:0] wb_wdata,
    input [31:0] wb_fp_wdata,
    input wb_flush,
    input wb_regwen,
    input wb_fp_regwen,

    output reg ex_id_ex_stall,
    
    output [31:0] ex_pc,
    output [31:0] ex_rd1,
    output [31:0] ex_rd2,
    output [31:0] ex_fd1,
    output [31:0] ex_fd2,
    output [31:0] ex_fd3,
    output [31:0] ex_imm,
    output [31:0] ex_inst,
    output ex_target_taken,
    output reg ex_fpu_valid,
    output ex_fwd_rs1,
    output ex_fwd_rs2,

    output id_stall
);
    wire id_ex_stall;
    wire stall;

    wire id_reg_rst = !id_ex_stall && (stall || ex_flush || rst || wb_flush);
    wire id_reg_we = !stall && !id_ex_stall && !ex_flush && !wb_flush;

    // MARK: InstSel

    wire [$clog2(`INST_SEL_NUM_INPUTS)-1:0] inst_sel = id_pc[30];
    wire [`INST_SEL_NUM_INPUTS*32-1:0] inst_mux_in;
    wire [31:0] id_inst;

    assign inst_mux_in[`INST_BIOS * 32 +: 32] = id_bios_inst;
    assign inst_mux_in[`INST_IMEM * 32 +: 32] = id_imem_inst;

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

    // MARK: Control
    assign id_stall = id_ex_stall || stall;
    wire fpu_valid;
    wire fwd_rs1;
    wire fwd_rs2;

    id_control control (
        .inst(id_inst),
        .ex_inst(ex_inst),
        .ex_fp_inst(ex_fp_inst),
        .fpu_busy(ex_fpu_busy),
    
        .imm_sel(imm_sel),
        .stall(stall),
        .id_ex_stall(id_ex_stall),
        .fpu_valid(fpu_valid),
        .fwd_rs1(fwd_rs1),
        .fwd_rs2(fwd_rs2)
    );

    // MARK: Pipeline registers

    wire [258:0] id = {
        fwd_rs1,
        fwd_rs2,
        id_pc,
        id_inst,
        rd1,
        rd2,
        fd1,
        fd2,
        fd3,
        imm,
        id_target_taken
    };

    reg [258:0] ex;

    always @(posedge clk) begin 
        if (id_reg_rst) begin 
            ex <= 259'd0;
        end else if (id_reg_we) begin 
            ex <= id;
        end
    end

    always @(posedge clk) begin 
        ex_fpu_valid <= fpu_valid;
        ex_id_ex_stall <= id_ex_stall;
    end

    assign ex_fwd_rs1 = ex[258];
    assign ex_fwd_rs2 = ex[257];
    assign ex_pc = ex[256:225];
    assign ex_inst = ex[224:193];
    assign ex_rd1 = ex[192:161];
    assign ex_rd2 = ex[160:129];
    assign ex_fd1 = ex[128:97];
    assign ex_fd2 = ex[96:65];
    assign ex_fd3 = ex[64:33];
    assign ex_imm = ex[32:1];
    assign ex_target_taken = ex[0];

endmodule