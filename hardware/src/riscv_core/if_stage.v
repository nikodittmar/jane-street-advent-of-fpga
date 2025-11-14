`include "control_sel.vh"

module if_stage #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input id_stall,
    input ex_stall,
    input mem_flush,
    input id_target_taken,
    input mem_redirect_taken,
    input [31:0] id_target,
    input [31:0] mem_alu,
    
    output [31:0] id_pc,
    output [31:0] if_addr,
    output if_bios_en
);  

    wire [31:0] if_pc;

    assign if_addr = if_pc;

    wire stall = id_stall | ex_stall;

    assign if_bios_en = if_pc[30] == `INST_BIOS;

    // MARK: Program Counter

    program_counter #(
        .RESET_PC(RESET_PC)
    ) program_counter (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .target_taken(id_target_taken),
        .target(id_target),
        .redirect_taken(mem_redirect_taken),
        .redirect(mem_alu),
        .pc_out(if_pc)
    );

    // MARK: Pipeline Registers

    wire pc_we = ~id_stall & ~ex_stall;

    pipeline_reg pc_reg (
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