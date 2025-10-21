`include "control_sel.vh"

module ex_stage (
    input clk,
    input rst,
    input [31:0] ex_pc,
    input [31:0] ex_rd1,
    input [31:0] ex_rd2,
    input [31:0] ex_imm,
    input ex_br_taken, // Branch predictor taken flag
    input [31:0] ex_inst,
    input [31:0] wb_wdata, // Forwarded result from WB stage
    input [31:0] wb_inst, // WB instruction for hazard detection
    
    output [31:0] ex_alu,
    output ex_br_mispred, // Branch mispredict flag
    output ex_flush, // Flush flag in the event of control hazards
    output mem_br_suc, // Branch prediction success flag
    output [31:0] mem_pc,
    output [31:0] mem_alu,
    output [31:0] mem_rd2,
    output [31:0] mem_inst
);

    wire ex_reg_rst;
    wire ex_reg_we;

    assign ex_reg_we = ~rst;
    assign ex_reg_rst = rst;

    // MARK: ALU

    wire [31:0] a;
    wire [31:0] b;

    wire [3:0] alu_sel;

    alu alu (
        .a(a),
        .b(b),
        .sel(alu_sel),

        .res(ex_alu)
    );

    // MARK: Branch Comp 

    wire brun;
    wire breq;
    wire brlt;

    branch_comp branch_comp (
        .d1(ex_rd1),
        .d2(ex_rd2),
        .un(brun),

        .eq(breq),
        .lt(brlt)
    );

    // MARK: CSR Register

    wire [31:0] csr_in;
    wire [31:0] tohost_csr;
    wire csr_we;

    pipeline_reg csr_reg (
        .clk(clk),
        .rst(rst),
        .we(csr_we),
        .in(csr_in),
        .out(tohost_csr)
    );

    // MARK: CSR Mux

    wire [$clog2(`CSR_MUX_NUM_INPUTS)-1:0] csr_mux_sel;
    wire [`CSR_MUX_NUM_INPUTS*32-1:0] csr_mux_in;

    assign csr_mux_in[`CSR_IMM * 32 +: 32] = ex_imm;
    assign csr_mux_in[`CSR_RD1 * 32 +: 32] = ex_rd1;
    
    mux #(
        .NUM_INPUTS(`CSR_MUX_NUM_INPUTS)
    ) csrw_mux (
        .in(csr_mux_in),
        .sel(csr_mux_sel),

        .out(csr_in)
    );

    // MARK: Forward A

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwda_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwda_in;
    wire [31:0] fwda_out;

    assign fwda_in[`EX_FWD_NONE * 32 +: 32] = ex_rd1;
    assign fwda_in[`EX_FWD_MEM * 32 +: 32] = mem_alu;
    assign fwda_in[`EX_FWD_WB * 32 +: 32] = wb_wdata;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwda_mux (
        .in(fwda_in),
        .sel(fwda_sel),

        .out(fwda_out)
    );

    // MARK: Forward B

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwdb_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwdb_in;
    wire [31:0] fwdb_out;

    assign fwdb_in[`EX_FWD_NONE * 32 +: 32] = ex_rd2;
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
    assign a_in[`A_PC * 32 +: 32] = ex_pc;
    
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
    assign b_in[`B_IMM * 32 +: 32] = ex_imm;

    mux #(
        .NUM_INPUTS(`B_NUM_INPUTS)
    ) b_mux (
        .in(b_in),
        .sel(b_sel),

        .out(b)
    );

    // MARK: Control Logic

    wire br_suc;

    ex_control control (
        .inst(ex_inst),
        .mem_inst(mem_inst),
        .wb_inst(wb_inst),
        .breq(breq),
        .brlt(brlt),
        .br_taken(ex_br_taken),

        .brun(brun),
        .fwda(fwda_sel),
        .fwdb(fwdb_sel),
        .asel(a_sel),
        .bsel(b_sel),
        .csr_mux_sel(csr_mux_sel),
        .csr_en(csr_we),
        .br_mispred(ex_br_mispred),
        .br_suc(br_suc),
        .alusel(alu_sel),
        .flush(ex_flush)
    );

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_pc),

        .out(mem_pc)
    );
    
    pipeline_reg alu_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_alu),

        .out(mem_alu)
    );

    pipeline_reg rd2_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_rd2),

        .out(mem_rd2)
    );

    pipeline_reg #(
        .WIDTH(1)
    ) br_suc_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(br_suc),

        .out(mem_br_suc)
    );

    pipeline_reg #(
        .RESET_VAL(`NOP)
    ) inst_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_inst),

        .out(mem_inst)
    );
endmodule