`include "control_sel.vh"
`include "../opcode.vh"

module mem_control (
    input [31:0] inst, pc, addr,
    output imemrw,
    output reg dmemrw, uartrw
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
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            `FNC2_SUB: begin
                // SUB
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            endcase
        `FNC_AND: begin
            // AND
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_OR: begin
            // OR
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_XOR: begin
            // XOR
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SLL: begin
            // SLL
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            `FNC2_SRA: begin
                // SRA
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SLTU: begin
            // SLTU
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            dmemrw = 1'b0;
                            uartrw = `UART_READ;
        end
        `FNC_SLL: begin
            // SLLI
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SLT: begin
            // SLTI
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SLTU: begin
            // SLTIU
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_XOR: begin
            // XORI
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_OR: begin
            // ORI
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_AND: begin
            // ANDI
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            `FNC2_SRA: begin
                // SRAI
                dmemrw = 1'b0;
                uartrw = `UART_READ;
            end
            endcase
        endcase
    
    `OPC_LOAD_5: begin
        
        // Using I/O memory
        case (addr)
            32'h00000000: uartrw = `UART_READ;
            32'h80000004: uartrw = `UART_READ;
            32'h80000008: uartrw = `UART_WRITE;
            32'h80000010: uartrw = `UART_READ;
            32'h80000014: uartrw = `UART_READ;
            32'h80000018: uartrw = `UART_WRITE;
            32'h8000001c: uartrw = `UART_READ;
            32'h80000020: uartrw = `UART_READ;
            32'h80000008: uartrw = `UART_READ;
            default: uartrw = `UART_READ;
        endcase

        case (funct3)
        `FNC_LB: begin
            // LB
            dmemrw = 1'b0;
        end
        `FNC_LH: begin
            // LH
            dmemrw = 1'b0;
        end
        `FNC_LW: begin
            // LW
            dmemrw = 1'b0;
        end
        `FNC_LBU: begin
            // LBU
            dmemrw = 1'b0;
        end
        `FNC_LHU: begin
            // LHU
            dmemrw = 1'b0;
        end
        endcase
    end

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            dmemrw = 1'b1;
        end
        `FNC_SH: begin
            // SH
            dmemrw = 1'b1;
        end
        `FNC_SW: begin
            // SW
            dmemrw = 1'b1;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_BNE: begin
            // BNE
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_BLT: begin
            // BLT
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_BGE: begin
            // BGE
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_BLTU: begin
            // BLTU
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        `FNC_BGEU: begin
            // BGEU
            dmemrw = 1'b0;
                uartrw = `UART_READ;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        dmemrw = 1'b0;
                uartrw = `UART_READ;
    end
    `OPC_JALR_5: begin
        // JALR
        dmemrw = 1'b0;
                uartrw = `UART_READ;
    end

    `OPC_LUI_5: begin
        // LUI
        dmemrw = 1'b0;
                uartrw = `UART_READ;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        dmemrw = 1'b0;
                uartrw = `UART_READ;
    end
    
    endcase
end

endmodule