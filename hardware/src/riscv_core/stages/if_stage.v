module if_stage (
    input clk,
    input mem_pcsel,
    input id_target_taken,
    input ex_branch_mispredict,
    input [31:0] mem_alu,
    input [31:0] id_target,
    input [31:0] ex_target,
    output [31:0] if_pc,
    output [31:0] if_addr
);

endmodule