`include "control_sel.vh"
`include "opcode.vh"

module id_control (
    input [31:0] inst,
    input [31:0] ex_inst,
    input [31:0] mem_inst,
    input [31:0] wb_inst,

    output reg [2:0] imm_sel,
    output reg [1:0] target_gen_sel,
    output reg [$clog2(`TGT_GEN_FWD_NUM_INPUTS)-1:0] target_gen_fwd_sel,
    output reg target_gen_en,
    output reg stall
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

wire [4:0] rs1;
wire has_rs1;

wire [4:0] rs2;
wire has_rs2;

wire [4:0] ex_rd;
wire ex_has_rd;

wire [4:0] mem_rd;
wire mem_has_rd;

wire [4:0] wb_rd;
wire wb_has_rd;

wire id_jump_inst;
wire ex_load_inst;
wire mem_load_inst;

assign rs1 = inst[19:15];
assign has_rs1 = inst[6:0] != `OPC_AUIPC && inst[6:0] != `OPC_LUI && inst[6:0] != `OPC_JAL && (inst[6:0] != `OPC_CSR || inst[14:12] == `FNC_CSRRW);

assign rs2 = inst[24:20];
assign has_rs2 = inst[6:0] == `OPC_ARI_RTYPE || inst[6:0] == `OPC_STORE || inst[6:0] == `OPC_BRANCH;

assign ex_rd = ex_inst[11:7];
assign ex_has_rd = ex_inst[6:0] != `OPC_STORE && ex_inst[6:0] != `OPC_BRANCH;

assign mem_rd = mem_inst[11:7];
assign mem_has_rd = mem_inst[6:0] != `OPC_STORE && mem_inst[6:0] != `OPC_BRANCH;

assign wb_rd = wb_inst[11:7];
assign wb_has_rd = wb_inst[6:0] != `OPC_STORE && wb_inst[6:0] != `OPC_BRANCH;

assign id_jump_inst = inst[6:2] == `OPC_JAL_5 | inst[6:2] == `OPC_JALR_5;
assign ex_load_inst = ex_inst[6:2] == `OPC_LOAD_5;
assign mem_load_inst = mem_inst[6:2] == `OPC_LOAD_5;

always @(*) begin
    imm_sel = `IMM_DONT_CARE;
    target_gen_sel = `TGT_GEN_DONT_CARE;
    target_gen_fwd_sel = `TGT_GEN_FWD_NONE;
    target_gen_en = 1'b0;
    stall = 1'b0;

    if (ex_has_rd && rs1 == ex_rd) begin 
        target_gen_fwd_sel = `TGT_GEN_FWD_EX;
    end else if (mem_has_rd && rs1 == mem_rd) begin
        target_gen_fwd_sel = `TGT_GEN_FWD_MEM;
    end else if (wb_has_rd && rs1 == wb_rd) begin 
        target_gen_fwd_sel = `TGT_GEN_FWD_WB;
    end

    if (ex_load_inst && ((has_rs2 && rs2 == ex_rd) || (has_rs1 && rs1 == ex_rd))) begin 
        stall = 1'b1;
    end

    case (opcode5)
    `OPC_ARI_RTYPE_5:
        case (funct3)
        `FNC_ADD_SUB:
            case (inst[30])
            `FNC2_ADD: begin
                // ADD
            end
            `FNC2_SUB: begin
                // SUB
            end
            endcase
        `FNC_AND: begin
            // AND
        end
        `FNC_OR: begin
            // OR
        end
        `FNC_XOR: begin
            // XOR
        end
        `FNC_SLL: begin
            // SLL
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
            end
            `FNC2_SRA: begin
                // SRA
            end
            endcase
        `FNC_SLT: begin
            // SLT
        end
        `FNC_SLTU: begin
            // SLTU
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
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        `FNC_BNE: begin
            // BNE
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        `FNC_BLT: begin
            // BLT
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        `FNC_BGE: begin
            // BGE
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        `FNC_BLTU: begin
            // BLTU
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        `FNC_BGEU: begin
            // BGEU
            target_gen_en = 1'b1;
            target_gen_sel = `TGT_GEN_BR;
            imm_sel = `IMM_B;
        end
        endcase
    `OPC_JAL_5: begin
        // JAL
        target_gen_en = 1'b1;
        target_gen_sel = `TGT_GEN_JAL;
        imm_sel = `IMM_J;
    end
    `OPC_JALR_5: begin
        // JALR
        if (!ex_load_inst || rs1 != ex_rd) begin
            target_gen_en = 1'b1;
        end
        target_gen_sel = `TGT_GEN_JALR;
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