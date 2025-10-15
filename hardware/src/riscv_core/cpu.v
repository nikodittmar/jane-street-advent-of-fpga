`include "control/control_sel.vh"

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
    // MARK: Instruction Fetch (IF)

    reg [31:0] if_pc;

    // MARK: Instruction Decode (ID)

    wire [31:0] id_pc;
    wire [31:0] id_inst;

    wire id_reg_rst;
    wire id_reg_we;

    // ********** Modules **********

    wire wb_rf_we;
    wire [4:0] id_rf_ra1, id_rf_ra2, wb_rf_wa;
    wire [31:0] wb_rf_wd;
    wire [31:0] id_rf_rd1, id_rf_rd2;
    reg_file id_rf (
        .clk(clk),
        .we(wb_rf_we),
        .ra1(id_rf_ra1), .ra2(id_rf_ra2), .wa(wb_rf_wa),
        .wd(wb_rf_wd),

        .rd1(id_rf_rd1), .rd2(id_rf_rd2)
    );

    /*
    // For checkpoint 3

    wire wb_fprf_we;
    wire [4:0] id_fprf_ra1, id_fprf_ra2, id_fprf_ra3, wb_fprf_wa;
    wire [31:0] wb_fprf_wd;
    wire [31:0] id_fprf_rd1, id_fprf_rd2, id_fprf_rd3;
    fp_reg_file id_fprf (
        .clk(clk),
        .we(wb_fprf_we),
        .ra1(id_fprf_ra1), .ra2(id_fprf_ra2), .ra3(id_fprf_ra3), .wa(wb_fprf_wa),
        .wd(wb_fprf_wd),

        .rd1(id_fprf_rd1), .rd2(id_fprf_rd2), .rd3(id_fprf_rd3)
    );
    */

    wire [2:0] id_imm_gen_sel;
    wire [31:0] id_imm_gen_imm;
    imm_gen id_imm_gen (
        .inst(id_inst),
        .sel(id_imm_gen_sel),

        .imm(id_imm_gen_imm)
    );

    // ********** Control Logic **********

    id_control id_control (
        .inst(id_inst),
        
        .immsel(id_imm_gen_sel)
    );

    // ********** Pipeline Registers **********

    pipeline_reg id_pc_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_pc),

        .out(ex_pc)
    );

    pipeline_reg id_rd1_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_rf_rd1),

        .out(ex_rd1)
    );

    pipeline_reg id_rd2_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_rf_rd2),

        .out(ex_rd2)
    );

    pipeline_reg id_imm_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_imm_gen_imm),

        .out(ex_imm)
    );

    pipeline_reg id_inst_reg (
        .clk(clk),
        .rst(id_reg_rst),
        .we(id_reg_we),
        .in(id_inst),

        .out(ex_inst)
    );

    // MARK: Execute (EX)

    wire [31:0] ex_pc;
    wire [31:0] ex_rd1;
    wire [31:0] ex_rd2;
    wire [31:0] ex_imm;
    wire [31:0] ex_inst;

    wire ex_reg_rst;
    wire ex_reg_we;

    // ********** Modules **********
    wire [31:0] ex_alu_a;
    wire [31:0] ex_alu_b;
    wire [3:0] ex_alu_sel;
    wire [31:0] ex_alu_res;
    alu ex_alu (
        .a(ex_alu_a),
        .b(ex_alu_b),
        .sel(ex_alu_sel),

        .res(ex_alu_res),
    );

    wire [31:0] ex_branch_comp_d1 = ex_rd1;
    wire [31:0] ex_branch_comp_d2 = ex_rd1;
    wire ex_branch_comp_un;
    wire ex_branch_comp_eq;
    wire ex_branch_comp_lt;
    branch_comp ex_branch_comp (
        .d1(ex_branch_comp_d1),
        .d2(ex_branch_comp_d2),
        .un(ex_branch_comp_un),

        .eq(ex_branch_comp_eq),
        .lt(ex_branch_comp_lt)
    );

    // ********** Muxes **********

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] ex_fwda_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] ex_fwda_in;
    wire [31:0] ex_fwda_out;

    assign ex_fwda_in[`EX_FWD_NONE * 32 +: 32] = ex_rd1;
    assign ex_fwda_in[`EX_FWD_MEM * 32 +: 32] = 32'b0; // TODO
    assign ex_fwda_in[`EX_FWD_WB * 32 +: 32] = 32'b0; // TODO

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS),
    ) ex_fwda_mux (
        .in(ex_fwda_in),
        .sel(ex_fwda_sel),

        .out(ex_fwda_out)
    );

    wire [$clog2(`EX_FWD_NUM_INPUTS)-1:0] ex_fwdb_sel;
    wire [`EX_FWD_NUM_INPUTS*32-1:0] ex_fwdb_in;
    wire [31:0] ex_fwdb_out;

    assign ex_fwdb_in[`EX_FWD_NONE * 32 +: 32] = ex_rd2;
    assign ex_fwdb_in[`EX_FWD_MEM * 32 +: 32] = 32'b0; // TODO
    assign ex_fwdb_in[`EX_FWD_WB * 32 +: 32] = 32'b0; // TODO

    mux #(
        .NUM_INPUTS(`EX_FWD_NUM_INPUTS),
    ) ex_fwdb_mux (
        .in(ex_fwdb_in),
        .sel(ex_fwdb_sel),

        .out(ex_fwdb_out)
    );

    wire [$clog2(`A_NUM_INPUTS)-1:0] ex_a_sel;
    wire [`A_NUM_INPUTS*32-1:0] ex_a_in;

    assign ex_a_in[`A_REG * 32 +: 32] = ex_fwdb_out;
    assign ex_a_in[`A_PC * 32 +: 32] = ex_pc;
    
    mux #(
        .NUM_INPUTS(`A_NUM_INPUTS),
    ) ex_a_mux (
        .in(ex_a_in),
        .sel(ex_a_sel),

        .out(ex_alu_a)
    );

    wire [$clog2(`B_NUM_INPUTS)-1:0] ex_b_sel;
    wire [`B_NUM_INPUTS*32-1:0] ex_b_in;

    assign ex_b_in[`B_REG * 32 +: 32] = ex_fwdb_out;
    assign ex_b_in[`B_IMM * 32 +: 32] = ex_imm;

    mux #(
        .NUM_INPUTS(`B_NUM_INPUTS),
    ) ex_b_mux (
        .in(ex_b_in),
        .sel(ex_b_sel),

        .out(ex_alu_b)
    );

    // ********** Control Logic **********

    ex_control ex_control (
        .inst(ex_inst),
        .breq(ex_branch_comp_eq),
        .brlt(ex_branch_comp_lt),

        .brun(ex_branch_comp_un),
        .fwda(ex_fwda_sel),
        .fwdb(ex_fwdb_sel),
        .asel(ex_a_sel),
        .bsel(ex_b_sel),
        .alusel(ex_alu_sel)
    );

    // ********** Pipeline Registers **********

    pipeline_reg ex_pc_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_pc),

        .out(mem_pc)
    );
    
    pipeline_reg ex_alu_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_alu_res),

        .out(mem_alu)
    );

    pipeline_reg ex_rd2_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_rd2),

        .out(mem_rd2)
    );

    pipeline_reg ex_inst_reg (
        .clk(clk),
        .rst(ex_reg_rst),
        .we(ex_reg_we),
        .in(ex_inst),

        .out(mem_inst)
    );


    // MARK: Memory (MEM)

    wire [31:0] mem_pc;
    wire [31:0] mem_alu;
    wire [31:0] mem_rd2;
    wire [31:0] mem_inst;

    wire mem_reg_rst;
    wire mem_reg_we;

    // ********** Modules **********

    // Data Memory
    // Synchronous read: read takes one cycle
    // Synchronous write: write takes one cycle
    // Write-byte-enable: select which of the four bytes to write
    wire [13:0] mem_dmem_addr;
    wire [31:0] mem_dmem_din, mem_dmem_dout;
    wire [3:0] mem_dmem_we;
    wire mem_dmem_en;
    dmem dmem (
      .clk(clk),
      .en(mem_dmem_en),
      .we(mem_dmem_we),
      .addr(mem_dmem_addr),
      .din(mem_dmem_din),
      .dout(mem_dmem_dout)
    );

    // On-chip UART
    //// UART Receiver
    wire [7:0] uart_rx_data_out;
    wire uart_rx_data_out_valid;
    wire uart_rx_data_out_ready;
    //// UART Transmitter
    wire [7:0] uart_tx_data_in;
    wire uart_tx_data_in_valid;
    wire uart_tx_data_in_ready;
    uart #(
        .CLOCK_FREQ(CPU_CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) on_chip_uart (
        .clk(clk),
        .reset(rst),

        .serial_in(serial_in),
        .data_out(uart_rx_data_out),
        .data_out_valid(uart_rx_data_out_valid),
        .data_out_ready(uart_rx_data_out_ready),

        .serial_out(serial_out),
        .data_in(uart_tx_data_in),
        .data_in_valid(uart_tx_data_in_valid),
        .data_in_ready(uart_tx_data_in_ready)
    );

    // ********** Control Logic **********

    mem_control mem_control (
        .inst(mem_inst),
        
    );

    // ********** Pipeline Registers **********

    pipeline_reg mem_pc_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_pc),

        .out(wb_pc)
    );
    
    pipeline_reg mem_alu_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_alu),

        .out(wb_alu)
    );

    pipeline_reg mem_inst_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_inst),

        .out(wb_inst)
    );

    // MARK: Writeback (WB)

    wire [31:0] wb_pc;
    wire [31:0] wb_alu;
    wire [31:0] wb_inst;

    // ********** Muxes **********

    wire [$clog2(`DOUT_NUM_INPUTS)-1:0] wb_dout_sel;
    wire [`DOUT_NUM_INPUTS*32-1:0] wb_dout_in;

    wire [31:0] wb_mem;

    assign wb_dout_in[`DOUT_BIOS * 32 +: 32] = mem_bios_dout;
    assign wb_dout_in[`DOUT_DMEM * 32 +: 32] = mem_dmem_dout;
    assign wb_dout_in[`DOUT_UART * 32 +: 32] = 31'b0; // TODO

    mux #(
        .NUM_INPUTS(`DOUT_NUM_INPUTS),
    ) wb_dout_mux (
        .in(wb_dout_in),
        .sel(wb_dout_sel),

        .out(wb_mem)
    );

    wire [$clog2(`WB_NUM_INPUTS)-1:0] wb_wb_sel;
    wire [`WB_NUM_INPUTS*32-1:0] wb_wb_in;

    assign wb_wb_in[`WB_PC4 * 32 +: 32] = wb_pc;
    assign wb_wb_in[`WB_ALU * 32 +: 32] = wb_alu;
    assign wb_wb_in[`WB_MEM * 32 +: 32] = wb_mem;

    mux #(
        .NUM_INPUTS(`WB_NUM_INPUTS),
    ) wb_wb_mux (
        .in(wb_wb_in),
        .sel(wb_wb_sel),

        .out() // TODO
    );

    // ********** Control Logic **********

    wb_control wb_control (
        .inst(mem_inst),
        
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
