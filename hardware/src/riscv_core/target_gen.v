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

always @ (*) begin
    target = 0;
    target_taken = 0;

    if (en) begin
        case(sel)
        `TGT_GEN_JAL: begin
            target = pc + $signed(imm);
            target_taken = 1;
        end
        `TGT_GEN_JALR: begin
            target = $signed(rd1) + $signed(imm);
            target_taken = 1;
        end
        `TGT_GEN_BR: begin
            if ($signed(imm) < 0) begin
                target = pc + $signed(imm);
                target_taken = 1;
            end
        end
        endcase
    end
end

endmodule