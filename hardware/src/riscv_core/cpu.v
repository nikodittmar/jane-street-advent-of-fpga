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

    wire ex_stall;
    wire id_stall;
    wire ex_flush;
    wire [31:0] id_bios_inst;
    wire [31:0] id_imem_inst;
    wire id_regwen;
    wire [31:0] if_pc_target;
    wire if_target_taken;
    wire ex_br_taken;
    wire [31:0] ex_rd1;
    wire [31:0] ex_rd2;
    wire [31:0] ex_imm;
    wire mem_br_suc;
    wire [31:0] mem_rd2;
    wire [31:0] wb_alu;
    wire [31:0] wb_pc4;
    wire [31:0] wb_dmem_dout;
    wire [31:0] wb_io_dout;
    wire wb_regwen;
    wire [31:0] wb_wdata;
    wire [31:0] mem_alu;

    // remove accidental dups
    // wire [31:0] wb_dmem_dout;
    // wire [31:0] wb_io_dout;

    // provide a generic MEM-side word address (used for IMEM writes)
    wire [13:0] mem_addr;

    // MARK: Instruction Fetch

    if_stage if_stage (
        .clk(clk),
        .rst(rst),
        .id_stall(id_stall),
        .id_target_taken(id_target_taken),
        .ex_br_mispred(ex_br_mispred),
        .id_target(id_target),
        .ex_alu(ex_alu),

        .ex_pc(ex_pc),
        .if_addr(if_addr)
    );

    // (keep wires; if IF doesn’t drive these yet, default them)
    // FIX: safe defaults so id_stage compiles if not produced yet
    assign if_pc_target = 32'b0;      // FIX
    assign if_target_taken = 1'b0;    // FIX

    // MARK: Instruction Decode

    id_stage id_stage (
        .clk(clk),
        .ex_flush(ex_flush),
        .id_pc(id_pc),
        .id_bios_inst(id_bios_inst),
        .id_imem_inst(id_imem_inst),
        .id_regwen(id_regwen),
        .ex_alu(ex_alu),
        .mem_alu(mem_alu),
        .mem_inst(mem_inst),
        .wb_wdata(wb_wdata),
        .wb_inst(wb_inst),

        .if_pc_target(if_pc_target),
        .if_target_taken(if_target_taken),
        .ex_br_taken(ex_br_taken),
        .ex_pc(ex_pc),
        .ex_rd1(ex_rd1),
        .ex_rd2(ex_rd2),
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
        .ex_imm(ex_imm),
        .ex_br_taken(ex_br_taken),
        .ex_inst(ex_inst),
        .wb_wdata(wb_wdata),
        .wb_inst(wb_inst),

        .ex_br_mispred(ex_br_mispred),
        .ex_flush(ex_flush),
        .mem_br_suc(mem_br_suc),
        .mem_pc(mem_pc),
        .mem_alu(mem_alu),
        .mem_rd2(mem_rd2),
        .mem_inst(mem_inst)
    );

    // MARK: Memory

    // IMEM A-port controls (from MEM stage)
    wire [31:0] mem_imem_din;
    wire [13:0] mem_imem_addr;
    wire [3:0]  mem_imem_we;
    wire        mem_imem_en;

    // IF B-port controls/returns
    wire [13:0] if_imem_addr;
    wire [31:0] if_imem_dout;
    wire        if_imem_en;

    mem_stage mem_stage (
        .clk(clk),
        .rst(rst),
        .mem_pc(mem_pc),
        .mem_alu(mem_alu), 
        .mem_rd2(mem_rd2),
        .mem_br_suc(mem_br_suc),
        .mem_inst(mem_inst),
        .wb_wdata(wb_wdata),
        .serial_in(serial_in),

        .serial_out(serial_out),
        .wb_alu(wb_alu),
        .wb_pc4(wb_pc4),
        .wb_dmem_dout(wb_dmem_dout), 
        .wb_io_dout(wb_io_dout),   // FIX: was wb_io_dout declared; pass-through
        .wb_inst(wb_inst),
        .mem_addr(mem_addr),

        .mem_imem_din(mem_imem_din),
        .mem_imem_we(mem_imem_we),
        .mem_imem_en(mem_imem_en)
        // if mem_stage actually has mem_imem_addr port, add it there;
        // we tie mem_imem_addr below to mem_addr to keep structure minimal
    );

    // tie address bus if mem_stage exposes only mem_addr (keep structure)
    assign mem_imem_addr = mem_addr; // FIX

    // MARK: Writeback

    wb_stage wb_stage (
        .clk(clk),
        .wb_alu(wb_alu),
        .wb_pc4(wb_pc4),
        .wb_bios_dout(wb_bios_dout), 
        .wb_dmem_dout(wb_dmem_dout), 
        .wb_io_dout(wb_io_dout),     // FIX: was mem_io_dout
        .wb_inst(wb_inst),           // FIX: was mem_inst

        .wb_regwen(wb_regwen),
        .wb_wdata(wb_wdata)
    );

    // MARK: Shared

    // BIOS Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    wire [11:0] mem_bios_addr, if_bios_addr;
    wire [31:0] wb_bios_dout, if_bios_dout;
    wire mem_bios_en, if_bios_en;

    // decode IF address: BIOS vs IMEM (keep minimal/generic)
    assign if_bios_en   = (if_addr[31:28] == 4'h4);  // RESET_PC base nibble
    assign if_bios_addr = if_addr[13:2];             // word index
    // keep BIOS A-port inactive unless you later write it from MEM
    assign mem_bios_en  = 1'b0;
    assign mem_bios_addr= 12'b0;

    bios_mem bios_mem (
      .clk(clk),
      .ena(mem_bios_en),
      .addra(mem_bios_addr),
      .douta(wb_bios_dout),
      .enb(if_bios_en),         // FIX: correct enables/addr/data mapping
      .addrb(if_bios_addr),     // FIX
      .doutb(if_bios_dout)      // FIX
    );

    // Instruction Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] if_imem_addr_unused; // (keep naming minimal)
    // non-BIOS fetches go to IMEM
    assign if_imem_en   = ~if_bios_en;
    assign if_imem_addr = if_addr[15:2]; // word index

    imem imem (
      .clk(clk),
      .ena(mem_imem_en),
      .wea(mem_imem_we),
      .addra(mem_imem_addr),
      .dina(mem_imem_din),
      .addrb(if_imem_addr),
      .doutb(if_imem_dout)
    );

    // Feed IF-side instruction words into ID inputs
    assign id_bios_inst = if_bios_dout;  // FIX: connect to ID
    assign id_imem_inst = if_imem_dout;  // FIX: connect to ID

    reg [31:0] tohost_csr = 0;
endmodule
