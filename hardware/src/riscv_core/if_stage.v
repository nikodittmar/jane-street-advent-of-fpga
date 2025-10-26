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
    output [31:0] if_addr,
    output if_bios_en
);  
    wire [31:0] if_pc;
    assign if_addr = if_pc;

    wire [31:0] pc4;
    assign pc4 = if_pc + 32'd4;

    wire [31:0] pc_out;
    wire [31:0] next_pc;

    // MARK: Program Counter

    program_counter #(
        .RESET_PC(RESET_PC)
    ) program_counter (
        .clk(clk),
        .rst(rst),
        .stall(id_stall),
        .pc_in(next_pc),

        .pc_out(pc_out)
    );

    // MARK: PC Override Mux

    wire [$clog2(`PC_MUX_NUM_INPUTS)-1:0] override_pc_sel;
    wire [`PC_MUX_NUM_INPUTS*32-1:0] override_pc_mux_in;

    assign override_pc_mux_in[`PC_4 * 32 +: 32] = pc_out;
    assign override_pc_mux_in[`PC_ALU * 32 +: 32] = ex_alu;
    assign override_pc_mux_in[`PC_TGT * 32 +: 32] = id_target;

    mux #(
        .NUM_INPUTS(`PC_MUX_NUM_INPUTS)
    ) override_pc_mux (
        .in(override_pc_mux_in),
        .sel(override_pc_sel),

        .out(if_pc)
    );

    // MARK: Next PC Mux

    wire [$clog2(`PC_MUX_NUM_INPUTS)-1:0] next_pc_sel;
    wire [`PC_MUX_NUM_INPUTS*32-1:0] nex_pc_mux_in;

    assign nex_pc_mux_in[`PC_4 * 32 +: 32] = pc4;
    assign nex_pc_mux_in[`PC_ALU * 32 +: 32] = ex_alu;
    assign nex_pc_mux_in[`PC_TGT * 32 +: 32] = id_target;

    mux #(
        .NUM_INPUTS(`PC_MUX_NUM_INPUTS)
    ) next_pc_mux (
        .in(nex_pc_mux_in),
        .sel(next_pc_sel),

        .out(next_pc)
    );

    // MARK: Control Logic

    if_control control (
        .pc(if_pc),
        .br_mispred(ex_br_mispred),
        .target_taken(id_target_taken),
        .stall(id_stall),

        .next_pc_sel(next_pc_sel),
        .override_pc_sel(override_pc_sel),
        .bios_en(if_bios_en)
    );

    // MARK: Pipeline Registers

    wire pc_we = ~id_stall;

    pipeline_reg #(
        .RESET_VAL(RESET_PC)
    ) pc_reg (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .in(if_pc),

        .out(id_pc)
    );

    /*
    // System Verilog Assertions 

    program_counter_eq_pc_reset_on_reset:
        assert property ( @(posedge clk)
            (rst) |=> (if_pc == RESET_PC)
        ) else $error("");
    */
endmodule