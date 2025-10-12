`include "alu_sel.vh"
`include "opcode.vh"

module ex_control (
    input [31:0] inst,
    input brlt, breq,
    output brun, 
    output [1:0] bsel, asel,
    output [3:0] alusel
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

case (opcode5)
`OPC_LUI_5:
    // LUI
`OPC_AUIPC_5:
    // AUIPC
`OPC_JAL_5:
    // JAL
`OPC_JALR_5:
    // JALR
`OPC_BRANCH_5:
    case (funct3)
    `FNC_BEQ:
        // BEQ
    `FNC_BNE:
        // BNE
    `FNC_BLT:
        // BLT
    `FNC_BGE:
        // BGE
    `FNC_BLTU:
        // BLTU
    `FNC_BGEU:
        // BGEU
    endcase
`OPC_STORE_5:
    case (funct3)
    `FNC_SB:
        // SB
    `FNC_SH:
        // SH
    `FNC_SW:
        // SW
    endcase
`OPC_LOAD_5:
    case (funct3)
    `FNC_LB:
        // LB
    `FNC_LH:
        // LH
    `FNC_LW:
        // LW
    `FNC_LBU:
        // LBU
    `FNC_LHU:
        // LHU
    endcase
`OPC_ARI_RTYPE_5:
    case (funct3)
    `FNC_ADD_SUB:
        case (inst[30])
        `FNC2_ADD:
        // ADD
        `FNC2_SUB:
        // SUB
        endcase
    `FNC_SLL:
        // SLL
    `FNC_SLT:
        // SLT
    `FNC_SLTU:
        // SLTU
    `FNC_XOR:
        // XOR
    `FNC_OR:
        // OR
    `FNC_AND:
        // AND
    `FNC_SRL_SRA:
        case (inst[30])
        `FNC2_SRL:
            // SRL
        `FNC2_SRA:
            // SRA
        endcase
    endcase
`OPC_ARI_ITYPE_5:
    case (funct3)
    `FNC_ADD_SUB:
        // ADDI
    `FNC_SLL:
        // SLLI
    `FNC_SLT:
        // SLTI
    `FNC_SLTU:
        // SLTIU
    `FNC_XOR:
        // XORI
    `FNC_OR:
        // ORI
    `FNC_AND:
        // ANDI
    `FNC_SRL_SRA:
        case (inst[30])
        `FNC2_SRL:
            // SRLI
        `FNC2_SRA:
            // SRAI
        endcase
    endcase
endcase

endmodule