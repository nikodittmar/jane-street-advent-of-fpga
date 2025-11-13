`include "control_sel.vh"
`include "opcode.vh"

module ex_control (
    input clk,
    input [31:0] inst,
    input [31:0] mem_inst,
    input breq, 
    input brlt,
    input br_taken,

    output reg brun, 
    output reg fwda, fwdb,
    output reg fwd_fpa, fwd_fpb, fwd_fpc,
    output reg asel, bsel,
    output reg fpa_sel,
    output reg csr_mux_sel,
    output reg csr_en,
    output reg br_suc,
    output reg [3:0] alusel,
    output reg [2:0] fpusel,
    output reg flush,
    output reg fpu_valid
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

wire [4:0] mem_rd;
wire mem_has_rd;

wire [4:0] mem_fd;
wire mem_has_fd;

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

assign mem_rd = mem_inst[11:7];
assign mem_has_rd = mem_inst[6:0] != `OPC_STORE && mem_inst[6:0] != `OPC_BRANCH && mem_inst[6:0] != `OPC_CSR && mem_inst[6:0] != `OPC_FP_LOAD && mem_inst[6:0] != `OPC_FP_STORE && mem_inst[6:0] != `OPC_FP_MADD && (mem_inst[6:0] != `OPC_FP || mem_inst[31:25] == `FNC7_FP_MV_X_W);

assign mem_fd = mem_inst[11:7];
assign mem_has_fd = mem_inst[6:0] == `OPC_FP_LOAD || mem_inst[6:0] == `OPC_FP_MADD || (mem_inst[6:0] == `OPC_FP && mem_inst[31:25] != `FNC7_FP_MV_X_W);

reg [31:0] last_inst;
reg inst_changed;

always @(posedge clk) begin 
    last_inst <= inst;
end

always @(*) begin
    inst_changed = last_inst != inst;

    brun = `BRUN_DONT_CARE;
    fwda = `EX_FWD_NONE;
    fwdb = `EX_FWD_NONE;
    fwd_fpa = `EX_FWD_NONE;
    fwd_fpb = `EX_FWD_NONE;
    fwd_fpc = `EX_FWD_NONE;
    fpa_sel = `FP_A_DONT_CARE;
    asel = `A_DONT_CARE;
    bsel = `B_DONT_CARE;
    csr_mux_sel = `CSR_DONT_CARE;
    csr_en = 1'b0;
    br_suc = 1'b0;
    alusel = `ALU_DONT_CARE;
    fpusel = `FPU_DONT_CARE;
    flush = 1'b0;
    fpu_valid = 1'b0;


    if (has_rs1 && mem_has_rd && rs1 == mem_rd) begin 
        fwda = `EX_FWD_MEM;
    end

    if (has_rs2 && mem_has_rd && rs2 == mem_rd) begin 
        fwdb = `EX_FWD_MEM;
    end

    if (has_fs1 && mem_has_fd && fs1 == mem_fd) begin 
        fwd_fpa = `EX_FWD_MEM;
    end

    if (has_fs2 && mem_has_fd && fs2 == mem_fd) begin 
        fwd_fpb = `EX_FWD_MEM;
    end

    if (has_fs3 && mem_has_fd && fs3 == mem_fd) begin 
        fwd_fpc = `EX_FWD_MEM;
    end
    
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
            alusel = `ALU_SLTU;
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
        end
        `FNC_SLTU: begin
            // SLTIU
            asel = `A_REG;
            bsel = `B_IMM;
            alusel = `ALU_SLTU;
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
            brun = 1'b0;
            if (breq == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = breq ? `ALU_ADD : `ALU_A_PLUS_4;
            end
        end
        `FNC_BNE: begin
            // BNE
            asel = `A_PC;
            bsel = `B_IMM;
            brun = 1'b0;
            if (breq != br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = !breq ? `ALU_ADD : `ALU_A_PLUS_4;
            end
        end
        `FNC_BLT: begin
            // BLT
            asel = `A_PC;
            bsel = `B_IMM;
            brun = 1'b0;
            if (brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = brlt ? `ALU_ADD : `ALU_A_PLUS_4;
            end
        end
        `FNC_BGE: begin
            // BGE
            asel = `A_PC;
            bsel = `B_IMM;
            brun = 1'b0;
            if (brlt != br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = !brlt ? `ALU_ADD : `ALU_A_PLUS_4;
            end
        end
        `FNC_BLTU: begin
            // BLTU
            asel = `A_PC;
            bsel = `B_IMM;
            brun = 1'b1;
            if (brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = brlt ? `ALU_ADD : `ALU_A_PLUS_4;
            end
        end
        `FNC_BGEU: begin
            // BGEU
            asel = `A_PC;
            bsel = `B_IMM;
            brun = 1'b1;
            if (brlt != br_taken) begin
                br_suc = 1'b1;
            end else begin 
                flush = 1'b1;
                alusel = !brlt ? `ALU_ADD : `ALU_A_PLUS_4;
            end
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
        asel = `A_REG;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
        flush = 1'b1;
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
    `OPC_CSR_5: begin
        case (funct3)
        `FNC_CSRRW: begin
            // CSRRW
            csr_mux_sel = `CSR_RD1;
            csr_en = 1'b1;
        end
        `FNC_CSRRWI: begin
            // CSRRWI
            csr_mux_sel = `CSR_IMM; 
            csr_en = 1'b1;
        end
        endcase
    end
    `OPC_FP_STORE_5: begin 
        // FSW
        fpusel = `FPU_BSEL;
        asel = `A_REG;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
        fpu_valid = inst_changed;
    end
    `OPC_FP_LOAD_5: begin 
        // FLW
        asel = `A_REG;
        bsel = `B_IMM;
        alusel = `ALU_ADD;
        fpu_valid = inst_changed;
    end
    `OPC_FP_5: begin 
        fpu_valid = inst_changed;
        case (funct4)
        `FNC4_FP_ADD: begin 
            // FADD
            fpa_sel = `FP_A_FP_REG;
            fpusel = `FPU_ADD;
        end
        `FNC4_FP_FSGNJ_S: begin 
            // FSGNJ.S
            fpa_sel = `FP_A_FP_REG;
            fpusel = `FPU_SGNJ;
        end
        `FNC4_FP_MV_X_W: begin 
            // FMV.X.W
            fpa_sel = `FP_A_FP_REG;
            fpusel = `FPU_ASEL;
        end
        `FNC4_FP_MV_W_X: begin 
            // FMV.W.X
            fpa_sel = `FP_A_REG;
            fpusel = `FPU_ASEL;
        end
        `FNC4_FP_CVT_S_W: begin 
            // FCVT.S.W
            fpa_sel = `FP_A_REG;
            fpusel = `FPU_CVT;
        end
        endcase
    end
    `OPC_FP_MADD_5: begin 
        // FMADD
        fpa_sel = `FP_A_FP_REG;
        fpusel = `FPU_MADD;
        fpu_valid = inst_changed;
    end
    endcase
end

endmodule