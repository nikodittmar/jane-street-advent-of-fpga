`include "control_sel.vh"

module mem_stage (
    input clk,
    input rst,
    input [31:0] mem_pc,
    input [31:0] mem_alu, 
    input [31:0] mem_rd2,
    input mem_br_suc, // Branch prediction success flag
    input [31:0] mem_inst,
    input [31:0] wb_wdata, // Forwarded result from WB stage
    input serial_in,

    output serial_out,
    output [31:0] wb_alu,
    output [31:0] wb_pc4,
    output [31:0] wb_dmem_dout, 
    output [31:0] wb_io_dout, 
    output [31:0] wb_inst,
    output [13:0] mem_addr,
    output [31:0] mem_imem_din,
    output [3:0] mem_imem_we,
    output mem_imem_en
);
    wire mem_reg_rst;
    wire mem_reg_we;

    assign mem_reg_we = ~rst;
    assign mem_reg_rst = rst;

    wire [3:0] we;
    wire [31:0] pc4 = mem_pc + 32'd4;
    wire [31:0] din;

    assign mem_imem_we = we;
    assign mem_imem_din = din;
    assign mem_addr = mem_alu[15:2];

    // MARK: Data In Mux

    wire [$clog2(`DIN_NUM_INPUTS)-1:0] din_mux_sel;
    wire [`DIN_NUM_INPUTS*32-1:0] din_mux_in;
    wire [31:0] din_mux_out;

    assign din_mux_in[`DIN_WDATA * 32 +: 32] = wb_wdata;
    assign din_mux_in[`DIN_RD2 * 32 +: 32] = mem_rd2;

    mux #(
        .NUM_INPUTS(`DIN_NUM_INPUTS)
    ) din_mux (
        .in(din_mux_in),
        .sel(din_mux_sel),

        .out(din_mux_out)
    );

    // MARK: Memory Packer

    wire [1:0] store_size;

    mem_pack mem_pack (
        .in(din_mux_out),
        .offset(mem_alu[1:0]),
        .size(store_size),

        .out(din),
        .we(we)
    );

    // MARK: DMem
    wire dmem_en;

    dmem dmem (
      .clk(clk),
      .en(dmem_en),
      .we(we),
      .addr(mem_addr),
      .din(din),

      .dout(wb_dmem_dout)
    );

    // MARK: IO

    wire io_en;
    wire br_inst;

    io io (
        .clk(clk),
        .rst(rst),
        .addr(mem_alu),
        .din(din),
        .io_en(io_en),
        .br_inst(br_inst),
        .br_suc(mem_br_suc),
        .serial_in(serial_in),

        .serial_out(serial_out),
        .dout(wb_io_dout)
    );

    // MARK: Control Logic

    mem_control control (
        .pc(mem_pc),
        .addr(mem_alu),
        .inst(mem_inst),
        .wb_inst(wb_inst),
        
        .din_sel(din_mux_sel),
        .size(store_size),
        .br_inst(br_inst),
        .imem_en(mem_imem_en),
        .dmem_en(dmem_en),
        .io_en(io_en)
    );

    // MARK: Pipeline Registers

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(pc4),

        .out(wb_pc4)
    );
    
    pipeline_reg alu_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_alu),

        .out(wb_alu)
    );

    pipeline_reg #(
        .RESET_VAL(`NOP)
    ) inst_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_inst),

        .out(wb_inst)
    );
endmodule