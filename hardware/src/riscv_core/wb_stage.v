`include "control_sel.vh"

module wb_stage (
    input clk,
    
    input [31:0] wb_inst,
    input [31:0] wb_fp_inst,
    input [31:0] wb_pc4,
    input [31:0] wb_alu,
    input [31:0] wb_fpu,
    input [31:0] wb_bios_dout, 
    input [31:0] wb_dmem_dout, 
    input [31:0] wb_io_dout, 

    output [31:0] wb_wdata,
    output [31:0] wb_fp_wdata,
    output wb_regwen,
    output wb_fp_regwen
);

    // MARK: Data Out Sel

    wire [$clog2(`DOUT_NUM_INPUTS)-1:0] dout_sel;
    wire [`DOUT_NUM_INPUTS*32-1:0] dout_mux_in;
    wire [31:0] mem;

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

    // MARK: Memory Mask

    wire [31:0] masked_mem;
    wire [3:0] mask;
    wire mask_un;

    mem_mask mem_mask ( 
        .din(mem),
        .mask(mask),
        .un(mask_un),
        
        .dout(masked_mem)
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

    // MARK: FP Writeback Mux

    wire [$clog2(`FP_WB_NUM_INPUTS)-1:0] fp_wb_sel;
    wire [`FP_WB_NUM_INPUTS*32-1:0] fp_wb_in;

    assign fp_wb_in[`FP_WB_ALU * 32 +: 32] = wb_alu;
    assign fp_wb_in[`FP_WB_FPU * 32 +: 32] = wb_fpu;
    assign fp_wb_in[`FP_WB_MEM * 32 +: 32] = masked_mem;

    mux #(
        .NUM_INPUTS(`FP_WB_NUM_INPUTS)
    ) fp_wb_mux (
        .in(fp_wb_in),
        .sel(fp_wb_sel),

        .out(wb_fp_wdata)
    );

    // MARK: Control Logic

    wb_control control (
        .inst(wb_inst),
        .fp_inst(wb_fp_inst),
        .addr(wb_alu),

        .mask(mask),
        .wb_sel(wb_sel),
        .fp_wb_sel(fp_wb_sel),
        .dout_sel(dout_sel),
        .mask_un(mask_un),
        .regwen(wb_regwen),
        .fp_regwen(wb_fp_regwen)
    );
endmodule