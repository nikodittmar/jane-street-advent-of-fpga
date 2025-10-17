`include "../control/control_sel.vh"

module ex_stage (
    input clk,
    input [31:0] id_pc,
    input [31:0] id_rd1,
    input [31:0] id_rd2,
    input [31:0] id_imm,
    input id_br_taken, // Branch predictor taken flag
    input [31:0] id_inst,
    input [31:0] mem_alu, // Forwarded result from Mem stage
    input [31:0] mem_inst, // MEM instruction for hazard detection
    input [31:0] wb_wdata, // Forwarded result from WB stage
    input [31:0] wb_inst, // WB instruction for hazard detection
    output ex_br_suc, // Branch prediction success flag
    output ex_br_mispred, // Branch mispredict flag
    output ex_stall, // Stall flag in the event of data hazards
    output ex_flush, // Flush flag in the event of control hazards
    output [31:0] ex_pc,
    output [31:0] ex_alu,
    output [31:0] ex_rd2,
    output [31:0] ex_inst
);

    wire ex_reg_rst;
    wire ex_reg_we;

    // MARK: ALU

    wire [31:0] a;
    wire [31:0] b;

    wire [3:0] alu_sel;
    wire [31:0] alu_res;

    alu alu (
        .a(a),
        .b(b),
        .sel(alu_sel),

        .res(alu_res),
    );

    // MARK: Branch Comp 

    wire brun;
    wire breq;
    wire brlt;

    branch_comp branch_comp (
        .d1(id_rd1),
        .d2(id_rd2),
        .un(brun),

        .eq(breq),
        .lt(brlt)
    );

    // MARK: Forward A

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwda_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwda_in;
    wire [31:0] fwda_out;

    assign fwda_in[`EX_FWD_NONE * 32 +: 32] = id_rd1;
    assign fwda_in[`EX_FWD_MEM * 32 +: 32] = mem_alu;
    assign fwda_in[`EX_FWD_WB * 32 +: 32] = wb_wdata;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS),
    ) fwda_mux (
        .in(fwda_in),
        .sel(fwda_sel),

        .out(fwda_out)
    );

    // MARK: Forward B

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwdb_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwdb_in;
    wire [31:0] fwdb_out;

    assign fwdb_in[`EX_FWD_NONE * 32 +: 32] = id_rd2;
    assign fwdb_in[`EX_FWD_MEM * 32 +: 32] = mem_alu;
    assign fwdb_in[`EX_FWD_WB * 32 +: 32] = wb_wdata;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwdb_mux (
        .in(fwdb_in),
        .sel(fwdb_sel),

        .out(fwdb_out)
    );

    // MARK: A Sel

    wire [$clog2(`A_NUM_INPUTS)-1:0] a_sel;
    wire [`A_NUM_INPUTS*32-1:0] a_in;

    assign a_in[`A_REG * 32 +: 32] = fwda_out;
    assign a_in[`A_PC * 32 +: 32] = id_pc;
    
    mux #(
        .NUM_INPUTS(`A_NUM_INPUTS)
    ) a_mux (
        .in(a_in),
        .sel(a_sel),

        .out(a)
    );

    // MARK: B Sel

    wire [$clog2(`B_NUM_INPUTS)-1:0] b_sel;
    wire [`B_NUM_INPUTS*32-1:0] b_in;

    assign b_in[`B_REG * 32 +: 32] = fwdb_out;
    assign b_in[`B_IMM * 32 +: 32] = id_imm;

    mux #(
        .NUM_INPUTS(`B_NUM_INPUTS)
    ) b_mux (
        .in(b_in),
        .sel(b_sel),

        .out(b)
    );

    // MARK: Control Logic

    ex_control control (
        .inst(id_inst),
        .breq(breq),
        .brlt(brlt),

        .brun(brun),
        .fwda(fwda_sel),
        .fwdb(fwdb_sel),
        .asel(a_sel),
        .bsel(b_sel),
        .alusel(alu_sel)
    );

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(id_pc),

        .out(ex_pc)
    );
    
    pipeline_reg alu_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(alu_res),

        .out(ex_alu)
    );

    pipeline_reg rd2_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(id_rd2),

        .out(ex_rd2)
    );

    pipeline_reg inst_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(id_inst),

        .out(ex_inst)
    );
endmodule