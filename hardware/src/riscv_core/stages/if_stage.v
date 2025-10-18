module if_stage (
    input clk,
    input rst, // Reset PC
    input id_target_taken,
    input ex_br_mispred,
    input stall,
    input [31:0] id_target,
    input [31:0] ex_alu,
    output [31:0] if_pc,
    output [31:0] if_addr
);

endmodule