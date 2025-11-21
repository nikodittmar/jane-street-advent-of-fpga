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
    wire [31:0] id_pc;
    wire [31:0] ex_pc;
    wire [31:0] mem_pc;
    wire [31:0] if_addr;
    wire [31:0] ex_inst;
    wire [31:0] mem_inst;
    wire [31:0] mem_fp_inst;
    wire [31:0] wb_inst;
    wire ex_target_taken;
    wire [31:0] ex_target;
    wire [31:0] ex_alu;
    wire id_stall;
    wire mem_flush;
    wire ex_stall;
    wire [31:0] id_bios_inst;
    wire [31:0] id_imem_inst;
    wire wb_fpregwen;
    wire wb_regwen;
    wire ex_br_taken;
    wire [31:0] ex_rd1;
    wire [31:0] ex_rd2;
    wire [31:0] ex_fd1;
    wire [31:0] ex_fd2;
    wire [31:0] ex_fd3;
    wire [31:0] ex_imm;
    wire mem_br_suc;
    wire [31:0] mem_rd2;
    wire [31:0] wb_alu;
    wire [31:0] wb_fpu;
    wire [31:0] wb_pc4;
    wire [31:0] wb_dmem_dout;
    wire [31:0] wb_io_dout;
    wire [31:0] wb_wdata;
    wire [31:0] mem_alu;
    wire [31:0] mem_fpu;
    wire [31:0] mem_addr;
    wire [31:0] wb_bios_dout;
    wire [31:0] mem_imem_din;
    wire [3:0] mem_imem_we;
    wire mem_imem_en;
    wire mem_bios_en;
    wire if_bios_en;
    wire [31:0] wb_fp_wdata;
    wire [31:0] wb_fp_inst;
    wire [31:0] mem_fd2;
    wire ex_fpu_almost_done;
    wire [31:0] ex_fp_inst;

    // MARK: Instruction Fetch

    if_stage #(
        .RESET_PC(RESET_PC)
    ) if_stage (
        .clk(clk),
        .rst(rst),
        .id_stall(id_stall),
        .mem_flush(mem_flush),
        .ex_target_taken(ex_target_taken),
        .ex_target(ex_target),
        .mem_alu(mem_alu),

        .id_pc(id_pc),
        .if_addr(if_addr),
        .if_bios_en(if_bios_en)
    );

    // MARK: Instruction Decode

    id_stage id_stage (
        .clk(clk),
        .rst(rst),
        .mem_flush(mem_flush),
        .id_pc(id_pc),
        .id_bios_inst(id_bios_inst),
        .id_imem_inst(id_imem_inst),
        .ex_fp_inst(ex_fp_inst),
        .mem_fp_inst(mem_fp_inst),
        .mem_inst(mem_inst),
        .wb_fpregwen(wb_fpregwen),
        .wb_regwen(wb_regwen),
        .wb_wdata(wb_wdata),
        .wb_inst(wb_inst),
        .wb_fp_wdata(wb_fp_wdata),
        .wb_fp_inst(wb_fp_inst),
        .ex_stall(ex_stall),
        .ex_fpu_almost_done(ex_fpu_almost_done),

        .ex_target(ex_target),
        .ex_target_taken(ex_target_taken),
        .ex_br_taken(ex_br_taken),
        .ex_pc(ex_pc),
        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
        .ex_fd1(ex_fd1),
        .ex_fd2(ex_fd2),
        .ex_fd3(ex_fd3),
        .ex_imm(ex_imm),
        .ex_inst(ex_inst),
        .id_stall(id_stall)
    );

    // MARK: Execute

    ex_stage ex_stage (
        .clk(clk),
        .rst(rst),
        .ex_pc(ex_pc),
        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
        .ex_fd1(ex_fd1),
        .ex_fd2(ex_fd2),
        .ex_fd3(ex_fd3),
        .ex_imm(ex_imm),
        .ex_br_taken(ex_br_taken),
        .ex_inst(ex_inst),

        .ex_alu(ex_alu),
        .mem_flush(mem_flush),
        .ex_stall(ex_stall),
        .mem_br_suc(mem_br_suc),
        .mem_pc(mem_pc),
        .mem_alu(mem_alu),
        .mem_fpu(mem_fpu),
        .mem_rd2(mem_rd2),
        .mem_fd2(mem_fd2),
        .mem_inst(mem_inst),
        .mem_fp_inst(mem_fp_inst),
        .ex_fp_inst(ex_fp_inst),
        .ex_fpu_almost_done(ex_fpu_almost_done)
    );

    // MARK: Memory

    mem_stage #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) mem_stage (
        .clk(clk),
        .rst(rst),
        .mem_pc(mem_pc),
        .mem_alu(mem_alu), 
        .mem_fpu(mem_fpu), 
        .mem_rd2(mem_rd2),
        .mem_fd2(mem_fd2),
        .mem_br_suc(mem_br_suc),
        .mem_inst(mem_inst),
        .mem_fp_inst(mem_fp_inst),
        .serial_in(serial_in),

        .serial_out(serial_out),
        .wb_alu(wb_alu),
        .wb_fpu(wb_fpu),
        .wb_pc4(wb_pc4),
        .wb_dmem_dout(wb_dmem_dout), 
        .wb_io_dout(wb_io_dout),
        .wb_inst(wb_inst),
        .wb_fp_inst(wb_fp_inst),
        .mem_addr(mem_addr),
        .ex_stall(ex_stall),

        .mem_imem_din(mem_imem_din),
        .mem_imem_we(mem_imem_we),
        .mem_imem_en(mem_imem_en),
        .mem_bios_en(mem_bios_en)
    );

    // MARK: Writeback

    wb_stage wb_stage (
        .clk(clk),
        .wb_alu(wb_alu),
        .wb_fpu(wb_fpu),
        .wb_pc4(wb_pc4),
        .wb_bios_dout(wb_bios_dout), 
        .wb_dmem_dout(wb_dmem_dout), 
        .wb_io_dout(wb_io_dout),
        .wb_inst(wb_inst),
        .wb_fp_inst(wb_fp_inst),

        .wb_regwen(wb_regwen),
        .wb_fpregwen(wb_fpregwen),
        .wb_wdata(wb_wdata),
        .wb_fp_wdata(wb_fp_wdata)
    );

    // MARK: BIOS Memory

    bios_mem bios_mem (
      .clk(clk),
      .ena(if_bios_en),
      .addra(if_addr[13:2]),
      .douta(id_bios_inst),
      .enb(mem_bios_en),
      .addrb(mem_addr[13:2]),
      .doutb(wb_bios_dout)
    );

    // MARK: Instruction Memory
    
    imem imem (
      .clk(clk),
      .rst(rst),
      .ena(mem_imem_en),
      .wea(mem_imem_we),
      .addra(mem_addr[15:2]),
      .dina(mem_imem_din),
      .addrb(if_addr[15:2]),
      .doutb(id_imem_inst)
    );

endmodule
