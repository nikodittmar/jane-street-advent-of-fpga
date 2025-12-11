`include "control_sel.vh"
`include "opcode.vh"

module ex_stage #(
    parameter CLOCK_FREQ = 125_000_000,
    parameter BAUD_RATE = 115_200
) (
    input clk,
    input rst,

    input [31:0] ex_pc,
    input [31:0] ex_inst,
    input [31:0] ex_rd1,
    input [31:0] ex_rd2,
    input [31:0] ex_fd1,
    input [31:0] ex_fd2,
    input [31:0] ex_fd3,
    input [31:0] ex_imm,
    input ex_target_taken,
    input ex_fpu_valid,
    input ex_fwd_rs1,
    input ex_fwd_rs2,

    input serial_in,
    output serial_out,

    output [31:0] ex_fp_inst,
    output [31:0] ex_din,
    output [31:0] ex_addr,
    output [31:0] ex_target,
    output [3:0] ex_we,
    output ex_target_valid,
    output ex_br_inst,
    output ex_br_taken,
    output ex_is_uncond,
    output ex_imem_en,
    output ex_bios_en,
    output ex_fpu_busy,
    output ex_flush,

    output [31:0] wb_inst,
    output [31:0] wb_fp_inst,
    output [31:0] wb_alu,
    output [31:0] wb_fpu,
    output [31:0] wb_pc4,
    output [31:0] wb_dmem_dout, 
    output [31:0] wb_io_dout,
    output [31:0] wb_redirect,
    output wb_flush
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

    // MARK: FPU

    wire [31:0] fp_a;
    wire [31:0] fp_b = ex_fd2;
    wire [31:0] fp_c;
    wire [31:0] fpu_out;
    wire [2:0] fpu_sel;

    fpu fpu (
        .clk(clk),
        .rst(rst),
        .a(fp_a),
        .b(fp_b),
        .c(fp_c),
        .sel(fpu_sel),
        .input_valid(ex_fpu_valid),
        .inst_in(ex_inst),
        
        .res(fpu_out),
        .busy(ex_fpu_busy),
        .inst_out(ex_fp_inst)
    );

    // MARK: FP A Sel

    wire [$clog2(`FP_A_NUM_INPUTS)-1:0] fp_a_sel;
    wire [`FP_A_NUM_INPUTS*32-1:0] fp_a_in;

    assign fp_a_in[`FP_A_FP_REG * 32 +: 32] = ex_fd1;
    assign fp_a_in[`FP_A_REG * 32 +: 32] = ex_rd1;
    
    mux #(
        .NUM_INPUTS(`FP_A_NUM_INPUTS)
    ) fp_a_mux (
        .in(fp_a_in),
        .sel(fp_a_sel),

        .out(fp_a)
    );

    // MARK: FP C Sel

    wire [$clog2(`FP_C_NUM_INPUTS)-1:0] fp_c_sel;
    wire [`FP_C_NUM_INPUTS*32-1:0] fp_c_in;

    assign fp_c_in[`FP_C_REG * 32 +: 32] = ex_fd3;
    assign fp_c_in[`FP_C_FWD * 32 +: 32] = wb_fpu;
    
    mux #(
        .NUM_INPUTS(`FP_C_NUM_INPUTS)
    ) fp_c_mux (
        .in(fp_c_in),
        .sel(fp_c_sel),

        .out(fp_c)
    );

    // MARK: ALU

    wire [31:0] a;
    wire [31:0] b;
    wire [3:0] alu_sel;
    wire [31:0] alu_out;

    assign ex_addr = alu_out;
    assign ex_target = alu_out;

    alu alu (
        .a(a),
        .b(b),
        .sel(alu_sel),

        .res(alu_out)
    );

    // MARK: A Sel

    wire [$clog2(`A_NUM_INPUTS)-1:0] a_sel;
    wire [`A_NUM_INPUTS*32-1:0] a_in;

    assign a_in[`A_REG * 32 +: 32] = ex_rd1;
    assign a_in[`A_FWD * 32 +: 32] = wb_alu;
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

    assign b_in[`B_REG * 32 +: 32] = ex_rd2;
    assign b_in[`B_FWD * 32 +: 32] = wb_alu;
    assign b_in[`B_IMM * 32 +: 32] = ex_imm;

    mux #(
        .NUM_INPUTS(`B_NUM_INPUTS)
    ) b_mux (
        .in(b_in),
        .sel(b_sel),

        .out(b)
    );

    `ifndef SYNTHESIS

    // MARK: CSR Register

    wire [31:0] csr_in;
    wire [31:0] tohost_csr;
    reg csr_en;

    pipeline_reg csr_reg (
        .clk(clk),
        .rst(rst),
        .we(csr_en),
        .in(csr_in),
        .out(tohost_csr)
    );

    // MARK: CSR Mux

    reg [$clog2(`CSR_MUX_NUM_INPUTS)-1:0] csr_mux_sel;
    wire [`CSR_MUX_NUM_INPUTS*32-1:0] csr_mux_in;

    assign csr_mux_in[`CSR_IMM * 32 +: 32] = { 27'b0, ex_inst[19:15] };
    assign csr_mux_in[`CSR_RD1 * 32 +: 32] = ex_rd1;
    
    mux #(
        .NUM_INPUTS(`CSR_MUX_NUM_INPUTS)
    ) csrw_mux (
        .in(csr_mux_in),
        .sel(csr_mux_sel),

        .out(csr_in)
    );

    wire [4:0] opcode5 = ex_inst[6:2];
    wire [2:0] funct3 = ex_inst[14:12];


    always @(*) begin 
        if (opcode5 == `OPC_CSR_5) begin
            csr_en = 1'b1;

            case (funct3)
            `FNC_CSRRW: begin
                // CSRRW
                csr_mux_sel = `CSR_RD1;
            end
            `FNC_CSRRWI: begin
                // CSRRWI
                csr_mux_sel = `CSR_IMM; 
            end
            endcase
        end else begin 
            csr_en = 1'b0;
        end
    end

    `endif

    // MARK: Din Mux

    wire [$clog2(`DIN_NUM_INPUTS)-1:0] din_mux_sel;
    wire [`DIN_NUM_INPUTS*32-1:0] din_mux_in;
    wire [31:0] din_mux_out;

    assign din_mux_in[`DIN_RD2 * 32 +: 32] = ex_rd2;
    assign din_mux_in[`DIN_FD2 * 32 +: 32] = ex_fd2;

    mux #(
        .NUM_INPUTS(`DIN_NUM_INPUTS)
    ) din_mux (
        .in(din_mux_in),
        .sel(din_mux_sel),

        .out(din_mux_out)
    );

    // MARK: Mem Pack

    wire [1:0] store_size;

    mem_pack mem_pack (
        .in(din_mux_out),
        .offset(alu_out[1:0]),
        .size(store_size),

        .out(ex_din),
        .we(ex_we)
    );

    // MARK: DMem

    wire dmem_en;

    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(ex_we),
      .addr(alu_out[15:2]),
      .din(ex_din),

      .dout(wb_dmem_dout)
    );

    // MARK: IO

    wire io_en;
    wire br_inst;
    wire br_suc;

    io #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) io (
        .clk(clk),
        .rst(rst),

        .addr(alu_out),
        .din(ex_din),
        .inst(wb_inst),
        .fp_inst(wb_fp_inst),
        .en(io_en),
        .br_suc(br_suc),
        .br_inst(br_inst),

        .serial_in(serial_in),
        .serial_out(serial_out),

        .dout(wb_io_dout)
    );

    // MARK: Redirect Mux

    wire [31:0] pc4 = ex_pc + 32'd4;

    wire [$clog2(`REDIR_NUM_INPUTS)-1:0] redirect_sel;
    wire [`REDIR_NUM_INPUTS*32-1:0] redirect_mux_in;
    wire [31:0] redirect;

    assign redirect_mux_in[`REDIR_ALU * 32 +: 32] = alu_out;
    assign redirect_mux_in[`REDIR_PC4 * 32 +: 32] = pc4;

    mux #(
        .NUM_INPUTS(`REDIR_NUM_INPUTS)
    ) redirect_mux (
        .in(redirect_mux_in),
        .sel(redirect_sel),

        .out(redirect)
    );

    // MARK: Pipeline Registers

    wire ex_reg_rst = rst || wb_flush;
    wire ex_reg_we = !rst && !wb_flush;

    wire ex_fp_reg_rst = rst || ex_fpu_busy || wb_flush;
    wire ex_fp_reg_we = !rst && !ex_fpu_busy;

    wire [63:0] ex_fp = { 
        fpu_out,
        ex_fp_inst
    };

    wire [128:0] ex = {
        ex_flush,
        redirect,
        pc4,
        alu_out,
        ex_inst
    };

    reg [63:0] wb_fp;
    reg [128:0] wb;

    always @(posedge clk) begin 
        if (ex_reg_rst) begin 
            wb <= 129'b0;
        end else if (ex_reg_we) begin 
            wb <= ex;
        end
    end

    always @(posedge clk) begin 
        if (ex_fp_reg_rst) begin 
            wb_fp <= 64'b0;
        end else if (ex_fp_reg_we) begin 
            wb_fp <= ex_fp;
        end
    end

    assign wb_flush = wb[128];
    assign wb_redirect = wb[127:96];
    assign wb_pc4 = wb[95:64];
    assign wb_alu = wb[63:32];
    assign wb_inst = wb[31:0];

    assign wb_fpu = wb_fp[63:32];
    assign wb_fp_inst = wb_fp[31:0];

    // MARK: Control Logic

    assign ex_target_valid = ex_is_uncond || br_inst;
    assign ex_br_inst = br_inst;

    ex_control control (
        .inst(ex_inst),
        .wb_inst(wb_fp_inst),
        .addr(alu_out),
        .pc(ex_pc),
        .breq(breq),
        .brlt(brlt),
        .target_taken(ex_target_taken),
        .fwd_rs1(ex_fwd_rs1),
        .fwd_rs2(ex_fwd_rs2),
    
        .alu_sel(alu_sel),
        .fpu_sel(fpu_sel),
        .a_sel(a_sel),
        .b_sel(b_sel),
        .size(store_size),
        .brun(brun),
        .fp_a_sel(fp_a_sel),
        .fp_c_sel(fp_c_sel),
        .br_suc(br_suc),
        .flush(ex_flush),
        .din_sel(din_mux_sel),
        .br_inst(br_inst),
        .imem_en(ex_imem_en),
        .dmem_en(dmem_en),
        .bios_en(ex_bios_en),
        .io_en(io_en),
        .redirect_sel(redirect_sel),
        .br_taken(ex_br_taken),
        .uncond(ex_is_uncond)
    );

endmodule