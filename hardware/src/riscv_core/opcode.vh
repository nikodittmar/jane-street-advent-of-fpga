// List of RISC-V opcodes and funct codes.
// Use `include "opcode.vh" to use these in the decoder

`ifndef OPCODE
`define OPCODE

// ***** Opcodes *****
// CSR instructions
`define OPC_CSR 7'b1110011

// Special immediate instructions
`define OPC_LUI         7'b0110111
`define OPC_AUIPC       7'b0010111

// Jump instructions
`define OPC_JAL         7'b1101111
`define OPC_JALR        7'b1100111

// Branch instructions
`define OPC_BRANCH      7'b1100011

// Load and store instructions
`define OPC_STORE       7'b0100011
`define OPC_LOAD        7'b0000011

// Arithmetic instructions
`define OPC_ARI_RTYPE   7'b0110011
`define OPC_ARI_ITYPE   7'b0010011

// CSR instruction
`define OPC_CSR         7'b1110011

// Floating point instructions
`define OPC_FP          7'b1010011

// Floating point load and store instructions
`define OPC_FP_STORE    7'b0100111
`define OPC_FP_LOAD     7'b0000111

// Floating point multiply add instruction
`define OPC_FP_MADD     7'b1000011

// ***** 5-bit Opcodes *****
`define OPC_LUI_5       5'b01101
`define OPC_AUIPC_5     5'b00101
`define OPC_JAL_5       5'b11011
`define OPC_JALR_5      5'b11001
`define OPC_BRANCH_5    5'b11000
`define OPC_STORE_5     5'b01000
`define OPC_LOAD_5      5'b00000
`define OPC_ARI_RTYPE_5 5'b01100
`define OPC_ARI_ITYPE_5 5'b00100

// 5-bit CSR opcodes
`define OPC_CSR_5       5'b11100

// 5-bit floating point opcodes
`define OPC_FP_STORE_5  5'b01001
`define OPC_FP_LOAD_5   5'b00001
`define OPC_FP_5        5'b10100
`define OPC_FP_MADD_5   5'b10000

// ***** Function codes *****

// Branch function codes
`define FNC_BEQ         3'b000
`define FNC_BNE         3'b001
`define FNC_BLT         3'b100
`define FNC_BGE         3'b101
`define FNC_BLTU        3'b110
`define FNC_BGEU        3'b111

// Load and store function codes
`define FNC_LB          3'b000
`define FNC_LH          3'b001
`define FNC_LW          3'b010
`define FNC_LBU         3'b100
`define FNC_LHU         3'b101
`define FNC_SB          3'b000
`define FNC_SH          3'b001
`define FNC_SW          3'b010

// Arithmetic R-type and I-type functions codes
`define FNC_ADD_SUB     3'b000
`define FNC_SLL         3'b001
`define FNC_SLT         3'b010
`define FNC_SLTU        3'b011
`define FNC_XOR         3'b100
`define FNC_OR          3'b110
`define FNC_AND         3'b111
`define FNC_SRL_SRA     3'b101

// CSR function codes
`define FNC_CSRRW       3'b001
`define FNC_CSRRWI      3'b101

// ADD and SUB use the same opcode + function code
// SRA and SRL also use the same opcode + function code
// For these operations, we also need to look at bit 30 of the instruction
`define FNC2_ADD        1'b0
`define FNC2_SUB        1'b1
`define FNC2_SRL        1'b0
`define FNC2_SRA        1'b1

`define FNC7_0  7'b0000000 // ADD, SRL
`define FNC7_1  7'b0100000 // SUB, SRA

// Floating point function codes
`define FNC4_FP_ADD     4'b0000
`define FNC4_FP_FSGNJ_S 4'b0010
`define FNC4_FP_MV_X_W  4'b1110
`define FNC4_FP_MV_W_X  4'b1111
`define FNC4_FP_CVT_S_W 4'b1101

`define FNC7_FP_ADD     7'b0000000
`define FNC7_FP_FSGNJ_S 7'b0010000
`define FNC7_FP_MV_X_W  7'b1110000
`define FNC7_FP_MV_W_X  7'b1111000
`define FNC7_FP_CVT_S_W 7'b1101000

`endif //OPCODE
