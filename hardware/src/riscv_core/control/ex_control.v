`include "control_sel.vh"
`include "../opcode.vh"

module ex_control (
    input [31:0] inst,
    input breq, brlt,
    output reg brun, 
    output reg asel, bsel,
    output reg [1:0] fwda, fwdb,
    output reg [3:0] alusel
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
                asel = `A_REG;
                bsel = `B_REG;
                alusel = `ALU_ADD;
            end
            `FNC2_SUB: begin
                // SUB
                asel = `A_REG;
                bsel = `B_REG;
                alusel = `ALU_SUB;
            end
            endcase
        `FNC_AND: begin
            // AND
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_AND;
        end
        `FNC_OR: begin
            // OR
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_OR;
        end
        `FNC_XOR: begin
            // XOR
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_XOR;
        end
        `FNC_SLL: begin
            // SLL
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_SLL;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                asel = `A_REG;
                bsel = `B_REG;
                alusel = `ALU_SRL;
            end
            `FNC2_SRA: begin
                // SRA
                asel = `A_REG;
                bsel = `B_REG;
                alusel = `ALU_SRA;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_SLT;
        end
        `FNC_SLTU: begin
            // SLTU
            asel = `A_REG;
            bsel = `B_REG;
            alusel = `ALU_SLT;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_SLL: begin
            // SLLI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_SLL;
        end
        `FNC_SLT: begin
            // SLTI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_SLT;
            brun = 1'b0;
        end
        `FNC_SLTU: begin
            // SLTIU
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_SLT;
            brun = 1'b1;
        end
        `FNC_XOR: begin
            // XORI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_XOR;
        end
        `FNC_OR: begin
            // ORI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_OR;
        end
        `FNC_AND: begin
            // ANDI
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_AND;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                asel = `A_REG;
                bsel = `B_IMM;
                alusel = `ALU_SRL;
            end
            `FNC2_SRA: begin
                // SRAI
                asel = `A_REG;
                bsel = `B_IMM;
                alusel = `ALU_SRA;
            end
            endcase
        endcase
    
    `OPC_LOAD_5:
        case (funct3)
        `FNC_LB: begin
            // LB
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_LH: begin
            // LH
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_LW: begin
            // LW
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_LBU: begin
            // LBU
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_LHU: begin
            // LHU
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        endcase

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_SH: begin
            // SH
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_SW: begin
            // SW
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_BNE: begin
            // BNE
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
        end
        `FNC_BLT: begin
            // BLT
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b0;
        end
        `FNC_BGE: begin
            // BGE
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b0;
        end
        `FNC_BLTU: begin
            // BLTU
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b1;
        end
        `FNC_BGEU: begin
            // BGEU
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b1;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        asel = `A_PC;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
    end
    `OPC_JALR_5: begin
        // JALR
        asel = `A_PC;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
    end

    `OPC_LUI_5: begin
        // LUI
        asel = `A_PC;
        bsel = `B_IMM;
        alusel = `ALU_BSEL;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        asel = `A_PC;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
    end
    
    endcase
end

endmodule