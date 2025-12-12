module cpu #(
    parameter CPU_CLOCK_FREQ = 50_000_000,
    parameter RESET_PC = 32'h4000_0000,
    parameter BAUD_RATE = 115200
) (
    input clk,
    input rst,
    input bp_enable,
    input serial_in,
    output serial_out
);

    // MARK: Wires
    wire [31:0] if_addr;
    wire if_bios_en;

    wire [31:0] id_pc;
    wire [31:0] id_bios_inst;
    wire [31:0] id_imem_inst;
    wire [31:0] id_target;
    wire id_stall;
    wire id_target_taken;

    wire [31:0] ex_target;
    wire [31:0] ex_pc;
    wire [31:0] ex_rd1;
    wire [31:0] ex_rd2;
    wire [31:0] ex_fd1;
    wire [31:0] ex_fd2;
    wire [31:0] ex_fd3;
    wire [31:0] ex_imm;
    wire [31:0] ex_inst;
    wire [31:0] ex_fp_inst;
    wire [31:0] ex_addr;
    wire [31:0] ex_din;
    wire [3:0] ex_we;
    wire ex_target_taken;
    wire ex_br_inst;
    wire ex_target_valid;
    wire ex_is_uncond;
    wire ex_br_taken;
    wire ex_bios_en;
    wire ex_imem_en;
    wire ex_fpu_busy;
    wire ex_fpu_valid;
    wire ex_flush;
    wire ex_fwd_rs1;
    wire ex_fwd_rs2;

    wire [31:0] wb_redirect;
    wire [31:0] wb_inst;
    wire [31:0] wb_fp_inst;
    wire [31:0] wb_alu;
    wire [31:0] wb_fpu;
    wire [31:0] wb_pc4;
    wire [31:0] wb_dmem_dout;
    wire [31:0] wb_bios_dout;
    wire [31:0] wb_io_dout;
    wire [31:0] wb_wdata;
    wire [31:0] wb_fp_wdata;
    wire wb_flush;
    wire wb_fp_regwen;
    wire wb_regwen;

    // MARK: BIOS Memory

    bios_mem bios_mem (
      .clk(clk),
      .ena(if_bios_en),
      .addra(if_addr[13:2]),
      .douta(id_bios_inst),
      .enb(ex_bios_en),
      .addrb(ex_addr[13:2]),
      .doutb(wb_bios_dout)
    );

    // MARK: Instruction Memory
    
    imem imem (
      .clk(clk),
      .rst(rst),
      .ena(ex_imem_en),
      .wea(ex_we),
      .addra(ex_addr[15:2]),
      .dina(ex_din),
      .addrb(if_addr[15:2]),
      .doutb(id_imem_inst)
    );

    // MARK: Branch Predictor

    branch_predictor bp (
        .rst(rst),
        .clk(clk),
        .if_addr(if_addr),
        .ex_addr(ex_pc),
        .ex_target(ex_target),
        .ex_target_valid(ex_target_valid),
        .ex_br_inst(ex_br_inst),
        .ex_is_uncond(ex_is_uncond),
        .ex_br_taken(ex_br_taken),
        .wb_flush(wb_flush),
        .id_stall(id_stall),

        .id_target(id_target),
        .id_target_taken(id_target_taken)
    );

    // MARK: Instruction Fetch

    if_stage #(
        .RESET_PC(RESET_PC)
    ) if_stage (
        .clk(clk),
        .rst(rst),

        .id_stall(id_stall),

        .id_target(id_target),
        .id_target_taken(id_target_taken),

        .ex_flush(ex_flush),

        .wb_redirect(wb_redirect),
        .wb_flush(wb_flush),

        .if_addr(if_addr),
        .if_bios_en(if_bios_en),

        .id_pc(id_pc)
    );

    // MARK: Instruction Decode

    wire ex_id_ex_stall;

    id_stage id_stage (
        .clk(clk),
        .rst(rst),

        .id_pc(id_pc),
        .id_bios_inst(id_bios_inst),
        .id_imem_inst(id_imem_inst),
        .id_target_taken(id_target_taken),

        .ex_fp_inst(ex_fp_inst),
        .ex_fpu_busy(ex_fpu_busy),
        .ex_flush(ex_flush),

        .wb_inst(wb_inst),
        .wb_fp_inst(wb_fp_inst),
        .wb_wdata(wb_wdata),
        .wb_fp_wdata(wb_fp_wdata),
        .wb_flush(wb_flush),
        .wb_regwen(wb_regwen),
        .wb_fp_regwen(wb_fp_regwen),

        .ex_id_ex_stall(ex_id_ex_stall),

        .ex_pc(ex_pc),
        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
        .ex_fd1(ex_fd1),
        .ex_fd2(ex_fd2),
        .ex_fd3(ex_fd3),
        .ex_imm(ex_imm),
        .ex_inst(ex_inst),
        .ex_target_taken(ex_target_taken),
        .ex_fpu_valid(ex_fpu_valid),
        .ex_fwd_rs1(ex_fwd_rs1),
        .ex_fwd_rs2(ex_fwd_rs2),

        .id_stall(id_stall)
    );

    // MARK: Execute

    ex_stage #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) ex_stage (
        .clk(clk),
        .rst(rst),

        .ex_id_ex_stall(ex_id_ex_stall),

        .ex_pc(ex_pc),
        .ex_inst(ex_inst),
        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
        .ex_fd1(ex_fd1),
        .ex_fd2(ex_fd2),
        .ex_fd3(ex_fd3),
        .ex_imm(ex_imm),
        .ex_target_taken(ex_target_taken),
        .ex_fpu_valid(ex_fpu_valid),
        .ex_fwd_rs1(ex_fwd_rs1),
        .ex_fwd_rs2(ex_fwd_rs2),

        .serial_in(serial_in),
        .serial_out(serial_out),

        .ex_fp_inst(ex_fp_inst),
        .ex_din(ex_din),
        .ex_addr(ex_addr),
        .ex_target(ex_target),
        .ex_we(ex_we),
        .ex_target_valid(ex_target_valid),
        .ex_br_inst(ex_br_inst),
        .ex_br_taken(ex_br_taken),
        .ex_is_uncond(ex_is_uncond),
        .ex_imem_en(ex_imem_en),
        .ex_bios_en(ex_bios_en),
        .ex_fpu_busy(ex_fpu_busy),
        .ex_flush(ex_flush),

        .wb_inst(wb_inst),
        .wb_fp_inst(wb_fp_inst),
        .wb_alu(wb_alu),
        .wb_fpu(wb_fpu),
        .wb_pc4(wb_pc4),
        .wb_dmem_dout(wb_dmem_dout),
        .wb_io_dout(wb_io_dout),
        .wb_redirect(wb_redirect),
        .wb_flush(wb_flush) 
    );

    // MARK: Writeback

    wb_stage wb_stage (
        .wb_inst(wb_inst),
        .wb_fp_inst(wb_fp_inst),
        .wb_pc4(wb_pc4),
        .wb_alu(wb_alu),
        .wb_fpu(wb_fpu),
        .wb_bios_dout(wb_bios_dout), 
        .wb_dmem_dout(wb_dmem_dout), 
        .wb_io_dout(wb_io_dout),
        
        .wb_wdata(wb_wdata),
        .wb_fp_wdata(wb_fp_wdata),
        .wb_regwen(wb_regwen),
        .wb_fp_regwen(wb_fp_regwen)
    );

//flushing: assert property(@(posedge clk) wb_flush |-> id_target_taken);
endmodule
