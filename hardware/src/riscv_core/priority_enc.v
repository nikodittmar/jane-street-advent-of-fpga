module priority_enc (
    input mem_pc_sel,
    input ex_branch_mispredict,
    input id_target_taken,
    output [1:0] pcsel
); 

// Priority
// 1. ex_branch_mispredict
// 2. id_target_taken
// 3. mem_pc_sel

// refer to control_sel.vh for pcsel encodings.

endmodule