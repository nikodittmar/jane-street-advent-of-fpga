`include "control_sel.vh"
`include "../opcode.vh"

module wb_control (
    input [31:0] inst, 
    input [31:0] addr,
    output reg [1:0] wbsel, 
    output reg [1:0] dsel,
    output [3:0] mask,
    output reg regwen
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
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SUB: begin
                // SUB
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            endcase
        `FNC_AND: begin
            // AND
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // OR
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XOR
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLL
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRA
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTU
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLLI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLT: begin
            // SLTI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTIU
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XORI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // ORI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_AND: begin
            // ANDI
            wbsel = `WB_ALU;
            dsel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRAI
                wbsel = `WB_ALU;
                dsel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            endcase
        endcase
    
    `OPC_LOAD_5:
        case (funct3)
        `FNC_LB: begin
            // LB
            wbsel = `WB_MEM;
            regwen = 1'b1;
            dsel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LH: begin
            // LH
            wbsel = `WB_MEM;
            regwen = 1'b1;
            dsel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LW: begin
            // LW
            wbsel = `WB_MEM;
            regwen = 1'b1;
            dsel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LBU: begin
            // LBU
            wbsel = `WB_MEM;
            regwen = 1'b1;
            dsel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LHU: begin
            // LHU
            wbsel = `WB_MEM;
            regwen = 1'b1;
            dsel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        endcase

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_SH: begin
            // SH
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_SW: begin
            // SW
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_BNE: begin
            // BNE
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_BLT: begin
            // BLT
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_BGE: begin
            // BGE
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_BLTU: begin
            // BLTU
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        `FNC_BGEU: begin
            // BGEU
            dsel = `DOUT_DMEM;
            regwen = 1'b0;
            wbsel = `WDATA_DONT_CARE;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        wbsel = `WB_PC4;
        dsel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    `OPC_JALR_5: begin
        // JALR
        wbsel = `WB_PC4;
        dsel = `DOUT_DMEM;
        regwen = 1'b1;
    end

    `OPC_LUI_5: begin
        // LUI
        wbsel = `WB_ALU;
        dsel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        wbsel = `WB_ALU;
        dsel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    
    endcase
end

endmodule