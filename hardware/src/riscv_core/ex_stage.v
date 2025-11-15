`include "control_sel.vh"

module ex_stage (
    input clk,
    input rst,
    input [31:0] ex_pc,
    input [31:0] ex_rd1,
    input [31:0] ex_rd2,
    input [31:0] ex_fd1,
    input [31:0] ex_fd2,
    input [31:0] ex_fd3,
    input [31:0] ex_imm,
    input ex_br_taken, // Branch predictor taken flag
    input [31:0] ex_inst,
    
    output [31:0] ex_alu,
    output mem_flush, // Flush flag in the event of control hazards
    output ex_stall,
    output mem_br_suc, // Branch prediction success flag
    output [31:0] mem_pc,
    output [31:0] mem_alu,
    output [31:0] mem_fpu,
    output [31:0] mem_rd2,
    output [31:0] mem_inst
);

    wire ex_reg_rst;
    wire ex_reg_we;

    assign ex_reg_we = ~rst & ~ex_stall;
    assign ex_reg_rst = rst | ex_stall | mem_flush;

    // MARK: FPU

    wire [31:0] fp_a;
    wire [31:0] fp_b;
    wire [31:0] fp_c;

    wire [2:0] fpu_sel;
    wire [31:0] ex_fpu;
    wire fpu_valid;

    fpu fpu (
        .clk(clk),
        .rst(rst),
        .a(fp_a),
        .b(fp_b),
        .c(fp_c),
        .sel(fpu_sel),
        .input_valid(fpu_valid),
        .res(ex_fpu),
        .busy(ex_stall)
    );

    // MARK: Forward A

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwda_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwda_in;
    wire [31:0] fwda_out;

    assign fwda_in[`EX_FWD_NONE * 32 +: 32] = ex_rd1;
    assign fwda_in[`EX_FWD_MEM * 32 +: 32] = mem_alu;

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

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwdb_mux (
        .in(fwdb_in),
        .sel(fwdb_sel),

        .out(fwdb_out)
    );


    // MARK: Forward FP A

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwd_fpa_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwd_fpa_in;
    wire [31:0] fwd_fpa_out;

    assign fwd_fpa_in[`EX_FWD_NONE * 32 +: 32] = ex_fd1;
    assign fwd_fpa_in[`EX_FWD_MEM * 32 +: 32] = mem_fpu;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwd_fpa_mux (
        .in(fwd_fpa_in),
        .sel(fwd_fpa_sel),

        .out(fwd_fpa_out)
    );

    // MARK: Forward FP B

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwd_fpb_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwd_fpb_in;

    assign fwd_fpb_in[`EX_FWD_NONE * 32 +: 32] = ex_fd2;
    assign fwd_fpb_in[`EX_FWD_MEM * 32 +: 32] = mem_fpu;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwd_fpb_mux (
        .in(fwd_fpb_in),
        .sel(fwd_fpb_sel),

        .out(fp_b)
    );

    // MARK: Forward FP C

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] fwd_fpc_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] fwd_fpc_in;

    assign fwd_fpc_in[`EX_FWD_NONE * 32 +: 32] = ex_fd3;
    assign fwd_fpc_in[`EX_FWD_MEM * 32 +: 32] = mem_fpu;

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS)
    ) fwd_fpc_mux (
        .in(fwd_fpc_in),
        .sel(fwd_fpc_sel),

        .out(fp_c)
    );

    // MARK: FP A Sel

    wire [$clog2(`A_NUM_INPUTS)-1:0] fpa_sel;
    wire [`A_NUM_INPUTS*32-1:0] fp_a_in;

    assign fp_a_in[`FP_A_FP_REG * 32 +: 32] = fwd_fpa_out;
    assign fp_a_in[`FP_A_REG * 32 +: 32] = fwda_out;
    
    mux #(
        .NUM_INPUTS(`A_NUM_INPUTS)
    ) fp_a_mux (
        .in(fp_a_in),
        .sel(fpa_sel),

        .out(fp_a)
    );


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

    assign csr_mux_in[`CSR_IMM * 32 +: 32] = { 27'b0, ex_inst[19:15]};
    assign csr_mux_in[`CSR_RD1 * 32 +: 32] = fwda_out;
    
    mux #(
        .NUM_INPUTS(`CSR_MUX_NUM_INPUTS)
    ) csrw_mux (
        .in(csr_mux_in),
        .sel(csr_mux_sel),

        .out(csr_in)
    );

    // MARK: Branch Comp 

    wire brun;
    wire breq;
    wire brlt;

    branch_comp branch_comp (
        .d1(fwda_out),
        .d2(fwdb_out),
        .un(brun),

        .eq(breq),
        .lt(brlt)
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
    wire flush;

    ex_control control (
        .clk(clk),
        .inst(ex_inst),
        .mem_inst(mem_inst),
        .breq(breq),
        .brlt(brlt),
        .br_taken(ex_br_taken),

        .brun(brun),
        .fwda(fwda_sel),
        .fwdb(fwdb_sel),
        .fwd_fpa(fwd_fpa_sel),
        .fwd_fpb(fwd_fpb_sel),
        .fwd_fpc(fwd_fpc_sel),
        .asel(a_sel),
        .bsel(b_sel),
        .fpa_sel(fpa_sel),
        .csr_mux_sel(csr_mux_sel),
        .csr_en(csr_we),
        .br_suc(br_suc),
        .alusel(alu_sel),
        .fpusel(fpu_sel),
        .flush(flush),
        .fpu_valid(fpu_valid)
    );

    // MARK: Pipeline Registers

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

    pipeline_reg fpu_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_fpu),

        .out(mem_fpu)
    );

    pipeline_reg rd2_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(fwdb_out),

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

    pipeline_reg #(
        .WIDTH(1)
    ) flush_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(flush),

        .out(mem_flush)
    );

    /*
    // MARK: Hazard Analysis
    reg [31:0] one_cycle_data_hazard;
    reg [31:0] two_cycle_data_hazard;

    reg [31:0] fp_one_cycle_data_hazard;
    reg [31:0] fp_two_cycle_data_hazard;

    reg [31:0] load_use_hazard_cnt;
    reg [31:0] fp_load_use_hazard_cnt;


    reg [31:0] fp_busy_cycle_cnt;

    always @(posedge clk) begin 
        if (rst) begin 
            one_cycle_data_hazard <= 32'b0;
            two_cycle_data_hazard <= 32'b0;
            fp_one_cycle_data_hazard <= 32'b0;
            fp_two_cycle_data_hazard <= 32'b0;
            fp_busy_cycle_cnt <= 32'b0;
            load_use_hazard_cnt <= 32'b0;
            fp_load_use_hazard_cnt <= 32'b0;
        end else begin 
            if (ex_inst != `NOP && !ex_stall) begin  // Avoid double counting for FPU stalls
                if (fwda_sel == `EX_FWD_MEM || fwdb_sel == `EX_FWD_MEM) begin 
                    one_cycle_data_hazard <= one_cycle_data_hazard + 32'b1;
                end

                if (fwda_sel == `EX_FWD_WB || fwdb_sel == `EX_FWD_WB) begin 
                    two_cycle_data_hazard <= two_cycle_data_hazard + 32'b1;
                end
                
                if (fwd_fpa_sel == `EX_FWD_MEM || fwd_fpb_sel == `EX_FWD_MEM || fwd_fpc_sel == `EX_FWD_MEM) begin
                    fp_one_cycle_data_hazard <= fp_one_cycle_data_hazard + 32'b1;
                end

                if (fwd_fpa_sel == `EX_FWD_WB || fwd_fpb_sel == `EX_FWD_WB || fwd_fpc_sel == `EX_FWD_WB) begin
                    fp_two_cycle_data_hazard <= fp_two_cycle_data_hazard + 32'b1;
                end

                if (fwda_sel == `EX_FWD_WB || fwdb_sel == `EX_FWD_WB || fwda_sel == `EX_FWD_MEM || fwdb_sel == `EX_FWD_MEM) begin 
                    load_use_hazard_cnt <= load_use_hazard_cnt + 32'b1;
                end
                
                if (fwd_fpa_sel == `EX_FWD_MEM || fwd_fpb_sel == `EX_FWD_MEM || fwd_fpc_sel == `EX_FWD_MEM || fwd_fpa_sel == `EX_FWD_WB || fwd_fpb_sel == `EX_FWD_WB || fwd_fpc_sel == `EX_FWD_WB) begin
                    fp_load_use_hazard_cnt <= fp_load_use_hazard_cnt + 32'b1;
                end
            end

            if (ex_stall) begin 
                fp_busy_cycle_cnt <= fp_busy_cycle_cnt + 32'b1;
            end
        end
    end

    */
endmodule