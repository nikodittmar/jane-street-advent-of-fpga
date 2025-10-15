`include "control_sel.vh"
`include "../opcode.vh"

module id_control (
    input [31:0] inst,
    output reg [2:0] immsel
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

always @ (*) begin
    case (opcode5)
    `OPC_ARI_RTYPE_5:
        case (funct3)
        `FNC_ADD_SUB:
            case (inst[30])
            `FNC2_ADD: begin
                // ADD
                immsel = `IMM_DONT_CARE;
            end
            `FNC2_SUB: begin
                // SUB
                immsel = `IMM_DONT_CARE;
            end
            endcase
        `FNC_AND: begin
            // AND
            immsel = `IMM_DONT_CARE;
        end
        `FNC_OR: begin
            // OR
            immsel = `IMM_DONT_CARE;
        end
        `FNC_XOR: begin
            // XOR
            immsel = `IMM_DONT_CARE;
        end
        `FNC_SLL: begin
            // SLL
            immsel = `IMM_DONT_CARE;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                immsel = `IMM_DONT_CARE;
            end
            `FNC2_SRA: begin
                // SRA
                immsel = `IMM_DONT_CARE;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            immsel = `IMM_DONT_CARE;
        end
        `FNC_SLTU: begin
            // SLTU
            immsel = `IMM_DONT_CARE;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            immsel = `IMM_I;
        end
        `FNC_SLL: begin
            // SLLI
            immsel = `IMM_I;
        end
        `FNC_SLT: begin
            // SLTI
            immsel = `IMM_I;
        end
        `FNC_SLTU: begin
            // SLTIU
            immsel = `IMM_I;
        end
        `FNC_XOR: begin
            // XORI
            immsel = `IMM_I;
        end
        `FNC_OR: begin
            // ORI
            immsel = `IMM_I;
        end
        `FNC_AND: begin
            // ANDI
            immsel = `IMM_I;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                immsel = `IMM_I;
            end
            `FNC2_SRA: begin
                // SRAI
                immsel = `IMM_I;
            end
            endcase
        endcase
    
    `OPC_LOAD_5:
        case (funct3)
        `FNC_LB: begin
            // LB
            immsel = `IMM_I;
        end
        `FNC_LH: begin
            // LH
            immsel = `IMM_I;
        end
        `FNC_LW: begin
            // LW
            immsel = `IMM_I;
        end
        `FNC_LBU: begin
            // LBU
            immsel = `IMM_I;
        end
        `FNC_LHU: begin
            // LHU
            immsel = `IMM_I;
        end
        endcase

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            immsel = `IMM_S;
        end
        `FNC_SH: begin
            // SH
            immsel = `IMM_S;
        end
        `FNC_SW: begin
            // SW
            immsel = `IMM_S;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            immsel = `IMM_B;
        end
        `FNC_BNE: begin
            // BNE
            immsel = `IMM_B;
        end
        `FNC_BLT: begin
            // BLT
            immsel = `IMM_B;
        end
        `FNC_BGE: begin
            // BGE
            immsel = `IMM_B;
        end
        `FNC_BLTU: begin
            // BLTU
            immsel = `IMM_B;
        end
        `FNC_BGEU: begin
            // BGEU
            immsel = `IMM_B;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        immsel = `IMM_J;
    end
    `OPC_JALR_5: begin
        // JALR
        immsel = `IMM_I;
    end

    `OPC_LUI_5: begin
        // LUI
        immsel = `IMM_U;

    end
    `OPC_AUIPC_5: begin
        // AUIPC
        immsel = `IMM_U;
    end
    
    endcase
end

endmodule