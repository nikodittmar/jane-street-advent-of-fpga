`include "control_sel.vh"
`include "opcode.vh"

module ex_control (
    input [31:0] inst,
    input [31:0] addr,
    input [31:0] pc,
    input breq,
    input brlt,
    input target_taken,
    
    output reg [$clog2(`ALU_NUM_OPS)-1:0] alu_sel,
    output reg [$clog2(`FPU_NUM_OPS)-1:0] fpu_sel,
    output reg [1:0] size,
    output reg brun,
    output reg a_sel,
    output reg b_sel,
    output reg fp_a_sel,
    output reg csr_mux_sel,
    output reg csr_en,
    output reg br_suc,
    output reg flush,
    output reg din_sel,
    output reg br_inst,
    output reg imem_en,
    output reg dmem_en,
    output reg bios_en,
    output reg io_en,
    output reg redirect_sel,
    output reg br_taken,
    output reg uncond
);

    wire [4:0] opcode5 = inst[6:2];
    wire [2:0] funct3 = inst[14:12];
    wire [6:0] funct7 = inst[31:25];
    wire [3:0] funct4 = inst[31:28];

    assign flush = uncond || target_taken != br_taken;
    assign br_suc = br_inst && target_taken == br_taken;

    always @(*) begin
        
        // Default Values
        alu_sel = `ALU_DONT_CARE;
        fpu_sel = `FPU_DONT_CARE;
        size = `MEM_SIZE_UNDEFINED;
        brun = `BRUN_DONT_CARE;
        a_sel = `A_DONT_CARE;
        b_sel = `B_DONT_CARE;
        fp_a_sel = `FP_A_DONT_CARE;
        csr_mux_sel = `CSR_DONT_CARE;
        csr_en = 1'b0;
        din_sel = `DIN_DONT_CARE;
        br_inst = 1'b0;
        imem_en = 1'b0;
        dmem_en = 1'b0; 
        bios_en = 1'b0;
        io_en = 1'b0;
        redirect_sel = `REDIR_DONT_CARE;
        br_taken = 1'b0;
        uncond = 1'b0;
        
        case (opcode5)
        `OPC_ARI_RTYPE_5: begin

            a_sel = `A_REG;
            b_sel = `B_REG;

            case (funct3)
            `FNC_ADD_SUB:
                case (inst[30])
                `FNC2_ADD: begin
                    // ADD
                    alu_sel = `ALU_ADD;
                end
                `FNC2_SUB: begin
                    // SUB
                    alu_sel = `ALU_SUB;
                end
                endcase
            `FNC_AND: begin
                // AND
                alu_sel = `ALU_AND;
            end
            `FNC_OR: begin
                // OR
                alu_sel = `ALU_OR;
            end
            `FNC_XOR: begin
                // XOR
                alu_sel = `ALU_XOR;
            end
            `FNC_SLL: begin
                // SLL
                alu_sel = `ALU_SLL;
            end
            `FNC_SRL_SRA:
                case (inst[30])
                `FNC2_SRL: begin
                    // SRL
                    alu_sel = `ALU_SRL;
                end
                `FNC2_SRA: begin
                    // SRA
                    alu_sel = `ALU_SRA;
                end
                endcase
            `FNC_SLT: begin
                // SLT
                alu_sel = `ALU_SLT;
            end
            `FNC_SLTU: begin
                // SLTU
                alu_sel = `ALU_SLTU;
            end
            endcase
        end
        `OPC_ARI_ITYPE_5: begin

            a_sel = `A_REG;
            b_sel = `B_IMM;

            case (funct3)
            `FNC_ADD_SUB: begin
                // ADDI
                alu_sel = `ALU_ADD;
            end
            `FNC_SLL: begin
                // SLLI
                alu_sel = `ALU_SLL;
            end
            `FNC_SLT: begin
                // SLTI
                alu_sel = `ALU_SLT;
            end
            `FNC_SLTU: begin
                // SLTIU
                alu_sel = `ALU_SLTU;
            end
            `FNC_XOR: begin
                // XORI
                alu_sel = `ALU_XOR;
            end
            `FNC_OR: begin
                // ORI
                alu_sel = `ALU_OR;
            end
            `FNC_AND: begin
                // ANDI
                alu_sel = `ALU_AND;
            end
            `FNC_SRL_SRA:
                case (inst[30])
                `FNC2_SRL: begin
                    // SRLI
                    alu_sel = `ALU_SRL;
                end
                `FNC2_SRA: begin
                    // SRAI
                    alu_sel = `ALU_SRA;
                end
                endcase
            endcase
        end
        `OPC_LOAD_5: begin

            a_sel = `A_REG;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;

            case (addr[31:28])
            `ADDR_IO: io_en = 1'b1;
            `ADDR_BIOS: bios_en = 1'b1;
            `ADDR_DMEM: dmem_en = 1'b1;
            `ADDR_MIRROR: dmem_en = 1'b1;
            endcase
        end
        `OPC_STORE_5: begin

            a_sel = `A_REG;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;

            case (addr[31:28])
            `ADDR_IO: begin 
                io_en = 1'b1;
            end
            `ADDR_DMEM: begin 
                dmem_en = 1'b1;
            end
            `ADDR_IMEM: begin 
                if (pc[30]) imem_en = 1'b1;
            end
            `ADDR_MIRROR: begin 
                if (pc[30]) imem_en = 1'b1;
                dmem_en = 1'b1;
            end
            endcase

            din_sel = `DIN_RD2;

            case (funct3)
            `FNC_SB: begin
                // SB
                size = `MEM_SIZE_BYTE;
            end
            `FNC_SH: begin
                // SH
                size = `MEM_SIZE_HALF;
            end
            `FNC_SW: begin
                // SW
                size = `MEM_SIZE_WORD;
            end
            endcase
        end
        `OPC_BRANCH_5: begin

            br_inst = 1'b1;

            a_sel = `A_PC;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;
            redirect_sel = target_taken;

            case (funct3)
            `FNC_BEQ: begin
                // BEQ
                brun = 1'b0;
                br_taken = breq;
            end
            `FNC_BNE: begin
                // BNE
                brun = 1'b0;
                br_taken = !breq;
            end
            `FNC_BLT: begin
                // BLT
                brun = 1'b0;
                br_taken = brlt;
            end
            `FNC_BGE: begin
                // BGE
                brun = 1'b0;
                br_taken = !brlt;
            end
            `FNC_BLTU: begin
                // BLTU
                brun = 1'b1;
                br_taken = brlt;
            end
            `FNC_BGEU: begin
                // BGEU
                brun = 1'b1;
                br_taken = !brlt;
            end
            endcase
        end
        `OPC_JAL_5: begin
            // JAL
            a_sel = `A_PC;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;
            uncond = 1'b1;
        end
        `OPC_JALR_5: begin
            // JALR
            a_sel = `A_REG;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;
            redirect_sel = `REDIR_ALU;
            uncond = 1'b1;
        end

        `OPC_LUI_5: begin
            // LUI
            a_sel = `A_PC;
            b_sel = `B_IMM;
            alu_sel = `ALU_BSEL;
        end
        `OPC_AUIPC_5: begin
            // AUIPC
            a_sel = `A_PC;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;
        end
        `OPC_CSR_5: begin

            csr_en = 1'b1;

            case (funct3)
            `FNC_CSRRW: begin
                // CSRRW
                csr_mux_sel = `CSR_RD1;
            end
            `FNC_CSRRWI: begin
                // CSRRWI
                csr_mux_sel = `CSR_IMM; 
            end
            endcase
        end
        `OPC_FP_STORE_5: begin 
            // FSW
            a_sel = `A_REG;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;
            din_sel = `DIN_FD2;
            size = `MEM_SIZE_WORD;

            case (addr[31:28])
            `ADDR_IO: begin 
                io_en = 1'b1;
            end
            `ADDR_DMEM: begin 
                dmem_en = 1'b1;
            end
            `ADDR_IMEM: begin 
                if (pc[30]) imem_en = 1'b1;
            end
            `ADDR_MIRROR: begin 
                if (pc[30]) imem_en = 1'b1;
                dmem_en = 1'b1;
            end
            endcase
        end
        `OPC_FP_LOAD_5: begin 
            // FLW
            a_sel = `A_REG;
            b_sel = `B_IMM;
            alu_sel = `ALU_ADD;

            case (addr[31:28])
            `ADDR_IO: io_en = 1'b1;
            `ADDR_BIOS: bios_en = 1'b1;
            `ADDR_DMEM: dmem_en = 1'b1;
            `ADDR_MIRROR: dmem_en = 1'b1;
            endcase
        end
        `OPC_FP_5: begin 
            case (funct4)
            `FNC4_FP_ADD: begin 
                // FADD
                fp_a_sel = `FP_A_FP_REG;
                fpu_sel = `FPU_ADD;
            end
            `FNC4_FP_FSGNJ_S: begin 
                // FSGNJ.S
                fp_a_sel = `FP_A_FP_REG;
                fpu_sel = `FPU_SGNJ;
            end
            `FNC4_FP_MV_X_W: begin 
                // FMV.X.W
                fp_a_sel = `FP_A_FP_REG;
                fpu_sel = `FPU_ASEL;
            end
            `FNC4_FP_MV_W_X: begin 
                // FMV.W.X
                fp_a_sel = `FP_A_REG;
                fpu_sel = `FPU_ASEL;
            end
            `FNC4_FP_CVT_S_W: begin 
                // FCVT.S.W
                fp_a_sel = `FP_A_REG;
                fpu_sel = `FPU_CVT;
            end
            endcase
        end
        `OPC_FP_MADD_5: begin 
            // FMADD
            fp_a_sel = `FP_A_FP_REG;
            fpu_sel = `FPU_MADD;
        end
        endcase
    end
endmodule