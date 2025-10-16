module target_gen (
    input [31:0] pc,
    input [1:0] sel,
    input [31:0] rd1,
    input [31:0] imm,
    output [31:0] target,
    output target_taken
);

// Refer to control_sel.vh for sel mappings 

// For jal, target = imm + pc, target_taken = 1

// For jalr, target = imm + rd1, target_taken = 1

// For branches, use forward backward prediction to determine if we should take the branch. 
// Set the address accordingly and target taken should only be 1 if we took the branch.

endmodule