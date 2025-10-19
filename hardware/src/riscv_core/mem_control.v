`include "control_sel.vh"
`include "opcode.vh"

module mem_control (
    input [31:0] inst, 
    input [31:0] wb_inst, // next instruction for hazard detection
    input [31:0] pc,
    input [31:0] addr,
    output din_sel, // Forwarding MUX selector
    output [3:0] we, // Bitmask
    output br_inst, // Branch instruction flag
    output imem_en,
    output reg dmem_en, 
    output io_en
);

// TODO: determine dsel behavior when in BIOS

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

// Write to IMEM if in BIOS
assign imemrw = pc[30] ? 1'b1 : 1'b0;

always @ (*) begin
    case (opcode5)
    `OPC_ARI_RTYPE_5:
        case (funct3)
        `FNC_ADD_SUB:
            case (inst[30])
            `FNC2_ADD: begin
                // ADD
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            `FNC2_SUB: begin
                // SUB
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            endcase
        `FNC_AND: begin
            // AND
            dmem_en = 1'b0;
                io_en = `IO_READ;
        end
        `FNC_OR: begin
            // OR
            dmem_en = 1'b0;
                io_en = `IO_READ;
        end
        `FNC_XOR: begin
            // XOR
            dmem_en = 1'b0;
                io_en = `IO_READ;
        end
        `FNC_SLL: begin
            // SLL
            dmem_en = 1'b0;
                io_en = `IO_READ;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            `FNC2_SRA: begin
                // SRA
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_SLTU: begin
            // SLTU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_SLL: begin
            // SLLI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_SLT: begin
            // SLTI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_SLTU: begin
            // SLTIU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_XOR: begin
            // XORI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_OR: begin
            // ORI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_AND: begin
            // ANDI
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            `FNC2_SRA: begin
                // SRAI
                dmem_en = 1'b0;
                io_en = `IO_READ;
            end
            endcase
        endcase
    
    `OPC_LOAD_5: begin
        case (funct3)
        `FNC_LB: begin
            // LB
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_LH: begin
            // LH
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_LW: begin
            // LW
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_LBU: begin
            // LBU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_LHU: begin
            // LHU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        endcase
    end

    `OPC_STORE_5: begin

        // Using I/O memory
        case (addr)
            32'h80000008: io_en = `IO_WRITE;
            32'h80000018: io_en = `IO_WRITE;
            default: io_en = `IO_READ;
        endcase

        case (funct3)
        `FNC_SB: begin
            // SB
            dmem_en = 1'b1;
        end
        `FNC_SH: begin
            // SH
            dmem_en = 1'b1;
        end
        `FNC_SW: begin
            // SW
            dmem_en = 1'b1;
        end
        endcase
    end
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_BNE: begin
            // BNE
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_BLT: begin
            // BLT
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_BGE: begin
            // BGE
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_BLTU: begin
            // BLTU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        `FNC_BGEU: begin
            // BGEU
            dmem_en = 1'b0;
            io_en = `IO_READ;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        dmem_en = 1'b0;
                io_en = `IO_READ;
    end
    `OPC_JALR_5: begin
        // JALR
        dmem_en = 1'b0;
                io_en = `IO_READ;
    end

    `OPC_LUI_5: begin
        // LUI
        dmem_en = 1'b0;
                io_en = `IO_READ;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        dmem_en = 1'b0;
                io_en = `IO_READ;
    end
    
    endcase
end

endmodule