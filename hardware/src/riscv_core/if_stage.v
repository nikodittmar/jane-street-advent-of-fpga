`include "control_sel.vh"

module if_stage #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,

    input id_stall,

    input [31:0] ex_target,
    input ex_target_taken,

    input [31:0] wb_alu,
    input wb_flush,
    
    output [31:0] if_addr,
    output if_bios_en,

    output [31:0] id_pc,
    output [1:0]  id_inst_sel
);  

    // MARK: Program Counter

    wire [31:0] if_pc;
    
    assign if_addr = if_pc;
    assign if_bios_en = if_pc[30];

    wire stall = id_stall;
    wire [31:0] in = wb_flush ? wb_alu : ex_target;
    wire in_valid = wb_flush || ex_target_taken;
    wire flush = wb_flush || ex_target_taken;
    
    program_counter #(
        .RESET_PC(RESET_PC)
    ) program_counter (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(flush),
        .in_valid(in_valid),
        .in(in),
        .out(if_pc)
    );

    // MARK: Pipeline Registers

    wire pc_we = !id_stall || flush;

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .in(if_pc),

        .out(id_pc)
    );

    wire [1:0] inst_sel = if_pc[30] ? `INST_BIOS : `INST_IMEM;

    pipeline_reg #(
        .WIDTH(2)
    ) inst_sel_reg (
        .clk(clk),
        .rst(rst),
        .we(pc_we),
        .in(inst_sel),

        .out(id_inst_sel)
    );

endmodule