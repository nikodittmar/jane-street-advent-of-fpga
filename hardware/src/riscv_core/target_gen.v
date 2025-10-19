`include "control_sel.vh"
module target_gen (
    input [31:0] pc,
    input [1:0] sel,
    input en,
    input [31:0] rd1,
    input [31:0] imm,
    output reg [31:0] target,
    output reg target_taken
);

// Refer to control_sel.vh for sel mappings 

// For jal, target = imm + pc, target_taken = 1

// For jalr, target = imm + rd1, target_taken = 1

// For branches, use forward backward prediction to determine if we should take the branch. 
// Set the address accordingly and target taken should only be 1 if we took the branch.

always @ (*) begin
    target = 0;
    target_taken = 0;

    if (en) begin
        case(sel)
        `TGT_GEN_JAL: begin
            target = imm + pc;
            target_taken = 1;
        end
        `TGT_GEN_JALR: begin
            target = imm + pc;
            target_taken = 1;
        end
        `TGT_GEN_BR: begin
            if ($signed(imm) < 0) begin
                target = pc + imm;
                target_taken = 1;
            end else begin
                target = 32'bx;
                target_taken = 1;
            end
        end
        endcase
    end
end

endmodule