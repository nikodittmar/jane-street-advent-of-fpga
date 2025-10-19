`include "control_sel.vh"
`include "opcode.vh"

module ex_control (
    input [31:0] inst,
    input [31:0] mem_inst,
    input [31:0] wb_inst,
    input breq, 
    input brlt,
    input br_taken,

    output reg brun, 
    output reg [1:0] fwda, fwdb,
    output reg asel, bsel,
    output reg csr_mux_sel,
    output reg csr_en,
    output reg br_mispred,
    output reg br_suc,
    output reg [3:0] alusel,
    output reg flush
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

wire [4:0] rs1;
wire [4:0] rs2;
wire [4:0] mem_rd;
wire [4:0] wb_rd;

assign rs1 = inst[19:15];
assign rs2 = inst[24:20];
assign mem_rd = mem_inst[11:7];
assign wb_rd = wb_inst[11:7];

always @(*) begin
    brun = `BRUN_DONT_CARE;
    fwda = `EX_FWD_NONE;
    fwdb = `EX_FWD_NONE;
    asel = `A_DONT_CARE;
    bsel = `B_DONT_CARE;
    csr_mux_sel = `CSR_DONT_CARE;
    csr_en = 1'b0;
    br_mispred = 1'b0;
    br_suc = 1'b0;
    alusel = `ALU_DONT_CARE;
    flush = 1'b0;


    if (rs1 == mem_rd) begin 
        fwda = `EX_FWD_MEM;
    end else if (rs1 == wb_rd) begin
        fwda = `EX_FWD_WB;
    end

    if (rs2 == mem_rd) begin 
        fwdb = `EX_FWD_MEM;
    end else if (rs2 == wb_rd) begin
        fwdb = `EX_FWD_WB;
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
            brun = 1'b0;
            if (breq == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
            end
        end
        `FNC_BNE: begin
            // BNE
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b0;
            if (!breq == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
            end
        end
        `FNC_BLT: begin
            // BLT
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b0;
            if (brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
            end
        end
        `FNC_BGE: begin
            // BGE
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b0;
            if (!brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
            end
        end
        `FNC_BLTU: begin
            // BLTU
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b1;
            if (brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
            end
        end
        `FNC_BGEU: begin
            // BGEU
            asel = `A_PC;
            bsel = `B_IMM;
            alusel = `ALU_ADD;
            brun = 1'b1;
            if (!brlt == br_taken) begin
                br_suc = 1'b1;
            end else begin 
                br_mispred = 1'b1;
                flush = 1'b1;
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
    endcase
end

endmodule