`include "control_sel.vh"

module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] sel,
    output reg [31:0] res
);
    always @(*) begin
        case (sel)
        `ALU_ADD:   res = a + b;
        `ALU_SLL:   res = a << b[4:0];
        `ALU_SLT:   res = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;
        `ALU_XOR:   res = a ^ b;
        `ALU_SRL:   res = a >> b[4:0];
        `ALU_OR:    res = a | b;
        `ALU_AND:   res = a & b;
        `ALU_SUB:   res = a - b;
        `ALU_SRA:   res = $signed(a) >>> b[4:0];
        `ALU_BSEL:  res = b;
        default:    res = 32'b0;
        endcase
    end
endmodule