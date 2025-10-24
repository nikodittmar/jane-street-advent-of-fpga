`include "control_sel.vh"

module if_stage #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input id_stall,
    input id_target_taken,
    input ex_br_mispred,
    input [31:0] id_target,
    input [31:0] ex_alu,
    
    output [31:0] id_pc,
    output [31:0] if_addr
);  
    wire [31:0] if_pc;
    assign if_addr = if_pc;

    wire [31:0] pc4;
    assign pc4 = if_pc + 32'd4;

    wire [31:0] next_pc;

    // MARK: Program Counter

    wire pc_we = ~id_stall;

    pipeline_reg #(
        .RESET_VAL(RESET_PC)
    ) program_counter (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .in(pc4),

        .out(next_pc)
    );

    // MARK: PC Mux

    wire [$clog2(`PC_MUX_NUM_INPUTS)-1:0] pc_sel;
    wire [`PC_MUX_NUM_INPUTS*32-1:0] pc_mux_in;

    assign pc_mux_in[`PC_4 * 32 +: 32] = id_stall ? id_pc : next_pc;
    assign pc_mux_in[`PC_ALU * 32 +: 32] = ex_alu;
    assign pc_mux_in[`PC_TGT * 32 +: 32] = id_target;

    mux #(
        .NUM_INPUTS(`PC_MUX_NUM_INPUTS)
    ) pc_mux (
        .in(pc_mux_in),
        .sel(pc_sel),

        .out(if_pc)
    );

    // MARK: Control Logic

    if_control control (
        .br_mispred(ex_br_mispred),
        .target_taken(id_target_taken),

        .pc_sel(pc_sel)
    );

    // MARK: Pipeline Registers

    pipeline_reg #(
        .RESET_VAL(RESET_PC)
    ) pc_reg (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .in(if_pc),

        .out(id_pc)
    );

endmodule