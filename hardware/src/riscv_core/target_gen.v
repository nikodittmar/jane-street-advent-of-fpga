`include "control_sel.vh"

module target_gen (
    input [31:0] pc,
    input sel,
    input en,
    input [31:0] imm,

    output reg [31:0] target,
    output reg target_taken,
    output reg branch_taken
);

always @ (*) begin
    target = 32'b0;
    target_taken = 1'b0;
    branch_taken = 1'b0;

    if (en) begin
        case(sel)
        `TGT_GEN_JAL: begin
            target = pc + $signed(imm);
            target_taken = 1'b1;
        end
        `TGT_GEN_BR: begin
            if ($signed(imm) < 0) begin
                target = pc + $signed(imm);
                target_taken = 1'b1;
                branch_taken = 1'b1;
            end
        end
        endcase
    end
end
endmodule