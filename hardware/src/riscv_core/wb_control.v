`include "control_sel.vh"
`include "opcode.vh"

module wb_control (
    input [31:0] inst, 
    input [31:0] addr,
    
    output reg [1:0] wb_sel, 
    output reg [1:0] dout_sel,
    output [3:0] mask,
    output mask_un,
    output reg regwen
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

always @ (*) begin
    wb_sel = `WB_DONT_CARE;
    dout_sel = `DOUT_DONT_CARE;
    mask = 4'b0000;
    mask_un = 1'b0;
    regwen = 1'b0;

    case (opcode5)
    `OPC_ARI_RTYPE_5:
        case (funct3)
        `FNC_ADD_SUB:
            case (inst[30])
            `FNC2_ADD: begin
                // ADD
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            `FNC2_SUB: begin
                // SUB
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            endcase
        `FNC_AND: begin
            // AND
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // OR
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XOR
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLL
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRA
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTU
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        endcase
    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLLI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SLT: begin
            // SLTI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTIU
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XORI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // ORI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_AND: begin
            // ANDI
            wb_sel = `WB_ALU;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRAI
                wb_sel = `WB_ALU;
                regwen = 1'b1;
            end
            endcase
        endcase
    `OPC_LOAD_5:
        case (funct3)
        `FNC_LB: begin
            // LB
            wb_sel = `WB_MEM;
            regwen = 1'b1;

            casez(addr[31:28])
            `ADDR_IO: dout_sel = `DOUT_IO;
            `ADDR_DMEM: dout_sel = `DOUT_DMEM;
            `ADDR_BIOS: dout_sel = `DOUT_BIOS;
            endcase

            case(addr[1:0])
            2'b00: mask = 4'b0001;
            2'b01: mask = 4'b0010;
            2'b10: mask = 4'b0100;
            2'b11: mask = 4'b1000;
            endcase
        end
        `FNC_LH: begin
            // LH
            wb_sel = `WB_MEM;
            regwen = 1'b1;

            casez(addr[31:28])
            `ADDR_IO: dout_sel = `DOUT_IO;
            `ADDR_DMEM: dout_sel = `DOUT_DMEM;
            `ADDR_BIOS: dout_sel = `DOUT_BIOS;
            endcase

            case(addr[1:0])
            2'b00: mask = 4'b0011;
            2'b10: mask = 4'b1100;
            endcase
        end
        `FNC_LW: begin
            // LW
            wb_sel = `WB_MEM;
            regwen = 1'b1;

            casez(addr[31:28])
            `ADDR_IO: dout_sel = `DOUT_IO;
            `ADDR_DMEM: dout_sel = `DOUT_DMEM;
            `ADDR_BIOS: dout_sel = `DOUT_BIOS;
            endcase

            mask = 4'b1111;
        end
        `FNC_LBU: begin
            // LBU
            wb_sel = `WB_MEM;
            regwen = 1'b1;

            casez(addr[31:28])
            `ADDR_IO: dout_sel = `DOUT_IO;
            `ADDR_DMEM: dout_sel = `DOUT_DMEM;
            `ADDR_BIOS: dout_sel = `DOUT_BIOS;
            endcase

            case(addr[1:0])
            2'b00: mask = 4'b0001;
            2'b01: mask = 4'b0010;
            2'b10: mask = 4'b0100;
            2'b11: mask = 4'b1000;
            endcase

            mask_un = 1'b1;
        end
        `FNC_LHU: begin
            // LHU
            wb_sel = `WB_MEM;
            regwen = 1'b1;

            casez(addr[31:28])
            `ADDR_IO: dout_sel = `DOUT_IO;
            `ADDR_DMEM: dout_sel = `DOUT_DMEM;
            `ADDR_BIOS: dout_sel = `DOUT_BIOS;
            endcase

            case(addr[1:0])
            2'b00: mask = 4'b0011;
            2'b10: mask = 4'b1100;
            endcase

            mask_un = 1'b1;
        end
        endcase
    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
        end
        `FNC_SH: begin
            // SH
        end
        `FNC_SW: begin
            // SW
        end
        endcase
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
        end
        `FNC_BNE: begin
            // BNE
        end
        `FNC_BLT: begin
            // BLT
        end
        `FNC_BGE: begin
            // BGE
        end
        `FNC_BLTU: begin
            // BLTU
        end
        `FNC_BGEU: begin
            // BGEU
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        wb_sel = `WB_PC4;
        regwen = 1'b1;
    end
    `OPC_JALR_5: begin
        // JALR
        wb_sel = `WB_PC4;
        regwen = 1'b1;
    end

    `OPC_LUI_5: begin
        // LUI
        wb_sel = `WB_ALU;
        regwen = 1'b1;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        wb_sel = `WB_ALU;
        regwen = 1'b1;
    end
    endcase
end

endmodule