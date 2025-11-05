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
wire [3:0] funct4;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];
assign funct4 = inst[31:28];

wire [4:0] rs1;
wire has_rs1;

wire [4:0] rs2;
wire has_rs2;

wire [4:0] fs1;
wire has_fs1;

wire [4:0] fs2;
wire has_fs2;

wire [4:0] fs3;
wire has_fs3;

wire [4:0] ex_rd;
wire ex_has_rd;

wire [4:0] ex_fd;
wire ex_has_fd;

wire [4:0] mem_rd;
wire mem_has_rd;

wire [4:0] mem_fd;
wire mem_has_fd;

wire [4:0] wb_rd;
wire wb_has_rd;

wire [4:0] wb_fd;
wire wb_has_fd;

assign rs1 = inst[19:15];
assign has_rs1 = inst[6:0] != `OPC_AUIPC && inst[6:0] != `OPC_LUI && inst[6:0] != `OPC_JAL && (inst[6:0] != `OPC_CSR || inst[14:12] == `FNC_CSRRW) && rs1 != 5'b0 && inst[6:0] != `OPC_FP_MADD && (inst[6:0] != `OPC_FP || inst[31:25] == `FNC7_FP_MV_W_X || inst[31:25] == `FNC7_FP_CVT_S_W);

assign rs2 = inst[24:20];
assign has_rs2 = (inst[6:0] == `OPC_ARI_RTYPE || inst[6:0] == `OPC_STORE || inst[6:0] == `OPC_BRANCH) && rs2 != 5'b0;

assign fs1 = inst[19:15];
assign has_fs1 = inst[6:0] == `OPC_FP_MADD || (inst[6:0] == `OPC_FP && (inst[31:25] == `FNC7_FP_MV_X_W || inst[31:25] == `FNC7_FP_FSGNJ_S || inst[31:25] == `FNC7_FP_ADD));

assign fs2 = inst[24:20];
assign has_fs2 = inst[6:0] == `OPC_FP_STORE || inst[6:0] == `OPC_FP_MADD || (inst[6:0] == `OPC_FP && (inst[31:25] == `FNC7_FP_FSGNJ_S || inst[31:25] == `FNC7_FP_ADD));

assign fs3 = inst[31:27];
assign has_fs3 = inst[6:0] == `OPC_FP_MADD;

assign ex_rd = ex_inst[11:7];
assign ex_has_rd = ex_inst[6:0] != `OPC_STORE && ex_inst[6:0] != `OPC_BRANCH && ex_inst[6:0] != `OPC_CSR && ex_inst[6:0] != `OPC_FP_LOAD && ex_inst[6:0] != `OPC_FP_STORE && ex_inst[6:0] != `OPC_FP_MADD && (ex_inst[6:0] != `OPC_FP || ex_inst[31:25] == `FNC7_FP_MV_X_W);

assign ex_fd = ex_inst[11:7];
assign ex_has_fd = ex_inst[6:0] == `OPC_FP_LOAD || ex_inst[6:0] == `OPC_FP_MADD || (ex_inst[6:0] == `OPC_FP && ex_inst[31:25] != `FNC7_FP_MV_X_W);

assign mem_rd = mem_inst[11:7];
assign mem_has_rd = mem_inst[6:0] != `OPC_STORE && mem_inst[6:0] != `OPC_BRANCH && mem_inst[6:0] != `OPC_CSR && mem_inst[6:0] != `OPC_FP_LOAD && mem_inst[6:0] != `OPC_FP_STORE && mem_inst[6:0] != `OPC_FP_MADD && (mem_inst[6:0] != `OPC_FP || mem_inst[31:25] == `FNC7_FP_MV_X_W);

assign mem_fd = mem_inst[11:7];
assign mem_has_fd = mem_inst[6:0] == `OPC_FP_LOAD || mem_inst[6:0] == `OPC_FP_MADD || (mem_inst[6:0] == `OPC_FP && mem_inst[31:25] != `FNC7_FP_MV_X_W);

assign wb_rd = wb_inst[11:7];
assign wb_has_rd = wb_inst[6:0] != `OPC_STORE && wb_inst[6:0] != `OPC_BRANCH && wb_inst[6:0] != `OPC_CSR && wb_inst[6:0] != `OPC_FP_LOAD && wb_inst[6:0] != `OPC_FP_STORE && wb_inst[6:0] != `OPC_FP_MADD && (wb_inst[6:0] != `OPC_FP || wb_inst[31:25] == `FNC7_FP_MV_X_W);

assign wb_fd = wb_inst[11:7];
assign wb_has_fd = wb_inst[6:0] == `OPC_FP_LOAD || wb_inst[6:0] == `OPC_FP_MADD || (wb_inst[6:0] == `OPC_FP && wb_inst[31:25] != `FNC7_FP_MV_X_W);

wire is_store;
wire id_jump_inst;
wire ex_load_inst;
wire mem_load_inst;

assign is_store = inst[6:0] == `OPC_STORE || inst[6:0] == `OPC_FP_STORE;

assign id_jump_inst = inst[6:2] == `OPC_JAL_5 || inst[6:2] == `OPC_JALR_5;
assign ex_load_inst = ex_inst[6:2] == `OPC_LOAD_5 || ex_inst[6:2] == `OPC_FP_LOAD_5;
assign mem_load_inst = mem_inst[6:2] == `OPC_LOAD_5 || mem_inst[6:2] == `OPC_FP_LOAD_5;

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

    if (ex_load_inst && // Only need to stall for load use data hazards
        (
            (is_store && rs1 == ex_rd) || // We only need to stall for store instructions with a data hazard surrounding the address
            (
                !is_store && // Store instructions do not need stalling for their store data
                (
                    (ex_has_rd && 
                        ((has_rs1 && rs1 == ex_rd) || (has_rs2 && rs2 == ex_rd))  // Only stall if we use a register that was written to
                    ) ||
                    (ex_has_fd && 
                        ((has_fs1 && fs1 == ex_fd) || (has_fs2 && fs2 == ex_fd) || (has_fs3 && fs3 == ex_fd))
                    )
            )))) // Only stall if we use a register that was written to
    begin
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
    `OPC_FP_STORE_5: begin 
        // FSW
        imm_sel = `IMM_S;
    end
    `OPC_FP_LOAD_5: begin 
        // FLW
        imm_sel = `IMM_I;
    end
    `OPC_FP_5: begin 
        case (funct4)
        `FNC4_FP_ADD: begin 
            // FADD
        end
        `FNC4_FP_FSGNJ_S: begin 
            // FSGNJ.S
        end
        `FNC4_FP_MV_X_W: begin 
            // FMV.X.W
        end
        `FNC4_FP_MV_W_X: begin 
            // FMV.W.X
        end
        `FNC4_FP_CVT_S_W: begin 
            // FCVT.S.W
        end
        endcase
    end
    `OPC_FP_MADD_5: begin 
        // FMADD
    end
    endcase
end

endmodule