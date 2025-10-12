// List of control signal mappings
// Use `include "control_sel.vh" to use these

`ifndef CONTROL_SEL
`define CONTROL_SEL

// ***** IF STAGE *****

// PC sel
`define PC_4            2'b00
`define PC_ALU          2'b01
`define PC_JUMP         2'b10

// Instruction sel
`define INST_BIOS       1'b0
`define INST_IMEM       1'b1

// ***** ID STAGE *****

// Immediate generator sel
`define IMM_I           3'b000 // I-type immediates
`define IMM_S           3'b001 // S-type immediates
`define IMM_B           3'b010 // B-type immediates
`define IMM_U           3'b011 // U-type immediates
`define IMM_J           3'b100 // J-type immediates

// ***** EX STAGE *****

// ALU A input sel
`define A_REG           1'b0
`define A_PC            1'b1

// ALU B input sel
`define B_REG           1'b0
`define B_IMM           1'b1

// ALU sel
`define ALU_ADD         4'b0000
`define ALU_SLL         4'b0001
`define ALU_SLT         4'b0010
`define ALU_XOR         4'b0100
`define ALU_SRL         4'b0101
`define ALU_OR          4'b0110
`define ALU_AND         4'b0111
`define ALU_SUB         4'b1100
`define ALU_SRA         4'b1101
`define ALU_BSEL        4'b1111

// ***** MEM STAGE *****

// Wdata sel
`define WDATA_MEM       2'b00
`define WDATA_ALU       2'b01
`define WDATA_FPU       2'b10

// MEM out sel
`define MEM_BIOS        1'b0
`define MEM_DMEM        1'b1

// ***** WB STAGE *****

// WB sel
`define WB_ALU          2'b00
`define WB_PC4          2'b01
`define WB_REG          2'b10

`endif // CONTROL_SEL