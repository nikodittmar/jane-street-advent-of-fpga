// List of ALU operations
// Use `include "alu_sel.vh" to use these

`ifndef ALU_SEL
`define ALU_SEL

`define ALU_ADD     4'b0000
`define ALU_SLL     4'b0001
`define ALU_SLT     4'b0010
`define ALU_XOR     4'b0100
`define ALU_SRL     4'b0101
`define ALU_OR      4'b0110
`define ALU_AND     4'b0111
`define ALU_SUB     4'b1100
`define ALU_SRA     4'b1101
`define ALU_BSEL    4'b1111

`endif //ALU_SEL