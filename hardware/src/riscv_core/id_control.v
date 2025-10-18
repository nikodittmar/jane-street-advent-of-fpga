`include "control_sel.vh"
`include "opcode.vh"

module id_control (
    input [31:0] inst,
    input [31:0] ex_inst,
    input [31:0] mem_inst,
    input [31:0] wb_inst,
    output reg [2:0] imm_sel,
    output [1:0] target_gen_sel,
    output [$clog2(`TGT_GEN_FWD_NUM_INPUTS)-1:0] target_gen_fwd_sel
);

// TODO: target_gen_sel logic

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
                imm_sel = `IMM_DONT_CARE;
            end
            `FNC2_SUB: begin
                // SUB
                imm_sel = `IMM_DONT_CARE;
            end
            endcase
        `FNC_AND: begin
            // AND
            imm_sel = `IMM_DONT_CARE;
        end
        `FNC_OR: begin
            // OR
            imm_sel = `IMM_DONT_CARE;
        end
        `FNC_XOR: begin
            // XOR
            imm_sel = `IMM_DONT_CARE;
        end
        `FNC_SLL: begin
            // SLL
            imm_sel = `IMM_DONT_CARE;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                imm_sel = `IMM_DONT_CARE;
            end
            `FNC2_SRA: begin
                // SRA
                imm_sel = `IMM_DONT_CARE;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            imm_sel = `IMM_DONT_CARE;
        end
        `FNC_SLTU: begin
            // SLTU
            imm_sel = `IMM_DONT_CARE;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            imm_sel = `IMM_I;
        end
        `FNC_SLL: begin
            // SLLI
            imm_sel = `IMM_I;
        end
        `FNC_SLT: begin
            // SLTI
            imm_sel = `IMM_I;
        end
        `FNC_SLTU: begin
            // SLTIU
            imm_sel = `IMM_I;
        end
        `FNC_XOR: begin
            // XORI
            imm_sel = `IMM_I;
        end
        `FNC_OR: begin
            // ORI
            imm_sel = `IMM_I;
        end
        `FNC_AND: begin
            // ANDI
            imm_sel = `IMM_I;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                imm_sel = `IMM_I;
            end
            `FNC2_SRA: begin
                // SRAI
                imm_sel = `IMM_I;
            end
            endcase
        endcase
    
    `OPC_LOAD_5:
        case (funct3)
        `FNC_LB: begin
            // LB
            imm_sel = `IMM_I;
        end
        `FNC_LH: begin
            // LH
            imm_sel = `IMM_I;
        end
        `FNC_LW: begin
            // LW
            imm_sel = `IMM_I;
        end
        `FNC_LBU: begin
            // LBU
            imm_sel = `IMM_I;
        end
        `FNC_LHU: begin
            // LHU
            imm_sel = `IMM_I;
        end
        endcase

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            imm_sel = `IMM_S;
        end
        `FNC_SH: begin
            // SH
            imm_sel = `IMM_S;
        end
        `FNC_SW: begin
            // SW
            imm_sel = `IMM_S;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            imm_sel = `IMM_B;
        end
        `FNC_BNE: begin
            // BNE
            imm_sel = `IMM_B;
        end
        `FNC_BLT: begin
            // BLT
            imm_sel = `IMM_B;
        end
        `FNC_BGE: begin
            // BGE
            imm_sel = `IMM_B;
        end
        `FNC_BLTU: begin
            // BLTU
            imm_sel = `IMM_B;
        end
        `FNC_BGEU: begin
            // BGEU
            imm_sel = `IMM_B;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        imm_sel = `IMM_J;
    end
    `OPC_JALR_5: begin
        // JALR
        imm_sel = `IMM_I;
    end

    `OPC_LUI_5: begin
        // LUI
        imm_sel = `IMM_U;

    end
    `OPC_AUIPC_5: begin
        // AUIPC
        imm_sel = `IMM_U;
    end
    
    endcase
end

endmodule