`include "control_sel.vh"
`include "opcode.vh"

module wb_stage (
    input clk,
    input [31:0] wb_alu,
    input [31:0] wb_fpu,
    input [31:0] wb_pc4,
    input [31:0] wb_bios_dout, 
    input [31:0] wb_dmem_dout, 
    input [31:0] wb_io_dout, 
    input [31:0] wb_inst,

    output wb_regwen,
    output wb_fpregwen,
    output [31:0] wb_wdata
);

    wire [31:0] mem;
    wire [31:0] masked_mem;
    wire [3:0] mask;

    // MARK: Data Out Sel
    wire [$clog2(`DOUT_NUM_INPUTS)-1:0] dout_sel;
    wire [`DOUT_NUM_INPUTS*32-1:0] dout_mux_in;

    assign dout_mux_in[`DOUT_BIOS * 32 +: 32] = wb_bios_dout;
    assign dout_mux_in[`DOUT_DMEM * 32 +: 32] = wb_dmem_dout;
    assign dout_mux_in[`DOUT_IO * 32 +: 32] = wb_io_dout;

    mux #(
        .NUM_INPUTS(`DOUT_NUM_INPUTS)
    ) dout_mux (
        .in(dout_mux_in),
        .sel(dout_sel),

        .out(mem)
    );

    // MARK: Writeback Mux

    wire [$clog2(`WB_NUM_INPUTS)-1:0] wb_sel;
    wire [`WB_NUM_INPUTS*32-1:0] wb_in;

    assign wb_in[`WB_PC4 * 32 +: 32] = wb_pc4;
    assign wb_in[`WB_ALU * 32 +: 32] = wb_alu;
    assign wb_in[`WB_MEM * 32 +: 32] = masked_mem;
    assign wb_in[`WB_FPU * 32 +: 32] = wb_fpu;

    mux #(
        .NUM_INPUTS(`WB_NUM_INPUTS)
    ) wb_mux (
        .in(wb_in),
        .sel(wb_sel),

        .out(wb_wdata)
    );

    // MARK: Memory Mask

    wire mask_un;

    mem_mask mem_mask ( 
        .din(mem),
        .mask(mask),
        .un(mask_un),
        
        .dout(masked_mem)
    );

    // MARK: Control Logic

    wb_control control (
        .inst(wb_inst),
        .addr(wb_alu),

        .wb_sel(wb_sel),
        .dout_sel(dout_sel),
        .mask(mask),
        .mask_un(mask_un),
        .regwen(wb_regwen),
        .fpregwen(wb_fpregwen)
    );

    /*
    // System Verilog Assertions

    load_byte_wb_wdata_upper_bits_are_zero:
        assert property ( @(posedge clk)
            (wb_inst == 32'h00000000)
            || !(wb_inst[6:2] == `OPC_LOAD_5 && wb_inst[14:12] == `FNC_LB)
            || (wb_wdata[31:8] == {24{wb_wdata[7]}})
        ) else $error("LB sign extension wrong! wb_wdata=%h inst=%h", wb_wdata, wb_inst);

    load_half_word_wb_wdata_upper_bits_are_zero:
        assert property ( @(posedge clk)
            (wb_inst == 32'h00000000)
            || !(wb_inst[6:2] == `OPC_LOAD_5 && wb_inst[14:12] == `FNC_LH)
            || (wb_wdata[31:16] == {16{wb_wdata[15]}})
        ) else $error("LH sign extension wrong! wb_wdata=%h inst=%h", wb_wdata, wb_inst);
    */
endmodule