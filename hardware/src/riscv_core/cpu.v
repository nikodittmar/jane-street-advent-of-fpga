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
    wire stall;
    wire flush;

    // Pipelined program counter
    wire [31:0] if_pc;
    wire [31:0] id_pc;
    wire [31:0] ex_pc;
    wire [31:0] mem_pc;
    wire [31:0] wb_pc;

    // Pipelined instructions
    wire [31:0] if_addr; // IF does not own the memory so it outputs an address
    wire [31:0] if_bios_inst;
    wire [31:0] if_imem_inst;
    wire [31:0] id_inst;
    wire [31:0] ex_inst;
    wire [31:0] mem_inst;
    wire [31:0] wb_inst;

    // Branch predictor/target generator signals
    wire id_target_taken;
    wire [31:0] id_target;
    wire ex_br_mispred;
    wire [31:0] ex_alu;


    // MARK: Instruction Fetch

    if_stage if_stage (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .id_target_taken(id_target_taken),
        .ex_br_mispred(ex_br_mispred),
        .id_target(id_target),
        .ex_alu(ex_alu),

        .if_pc(if_pc),
        .if_addr(if_addr)
    );

    // MARK: Instruction Decode

    id_stage id_stage (
        .clk(clk),
        .stall(stall),
        .flush(flush),
        .if_pc(if_pc),
        .if_bios_inst(if_bios_inst),
        .if_imem_inst(if_imem_inst),
        .wb_inst(wb_inst),
        .wb_wdata(),
        .wb_regwen(),
        .ex_alu(ex_alu),
        .ex_inst(),
        .mem_alu(),
        .mem_inst(),
        .wb_wdata(),
        .wb_inst(),

        .id_pc_target(),
        .id_target_taken(),
        .id_br_taken(),
        .id_pc(),
        .id_rd1(),
        .id_rd2(),
        .id_imm(),
        .id_inst()
    );

    // MARK: Execute

    ex_stage ex_stage (
        .clk(clk),
        .id_pc(),
        .id_rd1(),
        .id_rd2(),
        .id_imm(),
        .id_br_taken(),
        .id_inst(),
        .mem_alu(),
        .mem_inst(),
        .wb_wdata(),
        .wb_inst(),

        .ex_br_suc(),
        .ex_br_mispred(),
        .ex_stall(),
        .ex_flush(),
        .ex_pc(),
        .ex_alu(),
        .ex_rd2(),
        .ex_inst()
    );

    // MARK: Memory

    mem_stage mem_stage (
        .clk(clk),
        .ex_pc(),
        .ex_alu(), 
        .ex_rd2(),
        .ex_br_suc(),
        .ex_inst(),
        .wb_wdata(),
        .wb_inst(),
        .serial_in(serial_in),

        .serial_out(serial_out),
        .mem_alu(),
        .mem_pc4(),
        .mem_dmem_dout(), 
        .mem_io_dout(), 
        .mem_inst(),
        .mem_addr(),
        .mem_imem_din(),
        .mem_imem_wea(),
        .mem_imem_en()
    );

    // MARK: Writeback

    wb_stage wb_stage (
        .clk(clk),
        .mem_alu(),
        .mem_pc4(),
        .mem_bios_dout(), 
        .mem_dmem_dout(), 
        .mem_io_dout(), 
        .mem_inst(),

        .wb_regwen(),
        .wb_inst(),
        .wb_wdata()
    );

    // MARK: Shared

    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] mem_bios_addr, if_bios_addr;
    wire [31:0] mem_bios_dout, if_bios_dout;
    wire mem_bios_en, if_bios_en;
    bios_mem bios_mem (
      .clk(clk),
      .ena(mem_bios_en),
      .addra(mem_bios_addr),
      .douta(mem_bios_dout),
      .enb(if_bios_addr),
      .addrb(if_bios_dout),
      .doutb(if_bios_en)
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [31:0] mem_imem_din, if_imem_dout;
    wire [13:0] mem_imem_addr, if_imem_addr;
    wire [3:0] mem_imem_we;
    wire mem_imem_en;
    imem imem (
      .clk(clk),
      .ena(mem_imem_en),
      .wea(mem_imem_we),
      .addra(mem_imem_addr),
      .dina(mem_imem_din),
      .addrb(if_imem_addr),
      .doutb(if_imem_dout)
    );

    reg [31:0] tohost_csr = 0;
endmodule
