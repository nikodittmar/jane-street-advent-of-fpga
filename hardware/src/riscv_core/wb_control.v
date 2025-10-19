`include "control_sel.vh"
`include "opcode.vh"

module wb_control (
    input [31:0] inst, 
    input [31:0] addr,
    output reg [1:0] wb_sel, 
    output reg [1:0] dout_sel,
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
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SUB: begin
                // SUB
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            endcase
        `FNC_AND: begin
            // AND
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // OR
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XOR
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLL
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRL
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRA
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            endcase
        `FNC_SLT: begin
            // SLT
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTU
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        endcase

    `OPC_ARI_ITYPE_5:
        case (funct3)
        `FNC_ADD_SUB: begin
            // ADDI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLL: begin
            // SLLI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLT: begin
            // SLTI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SLTU: begin
            // SLTIU
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_XOR: begin
            // XORI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_OR: begin
            // ORI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_AND: begin
            // ANDI
            wb_sel = `WB_ALU;
            dout_sel = `DOUT_DMEM;
            regwen = 1'b1;
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
                regwen = 1'b1;
            end
            `FNC2_SRA: begin
                // SRAI
                wb_sel = `WB_ALU;
                dout_sel = `DOUT_DMEM;
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
            dout_sel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LH: begin
            // LH
            wb_sel = `WB_MEM;
            regwen = 1'b1;
            dout_sel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LW: begin
            // LW
            wb_sel = `WB_MEM;
            regwen = 1'b1;
            dout_sel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LBU: begin
            // LBU
            wb_sel = `WB_MEM;
            regwen = 1'b1;
            dout_sel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        `FNC_LHU: begin
            // LHU
            wb_sel = `WB_MEM;
            regwen = 1'b1;
            dout_sel = addr[31] ? `DOUT_UART : `DOUT_DMEM;
        end
        endcase

    `OPC_STORE_5:
        case (funct3)
        `FNC_SB: begin
            // SB
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_SH: begin
            // SH
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_SW: begin
            // SW
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        endcase
    
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_BNE: begin
            // BNE
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_BLT: begin
            // BLT
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_BGE: begin
            // BGE
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_BLTU: begin
            // BLTU
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        `FNC_BGEU: begin
            // BGEU
            dout_sel = `DOUT_DMEM;
            regwen = 1'b0;
            wb_sel = `WDATA_DONT_CARE;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
        wb_sel = `WB_PC4;
        dout_sel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    `OPC_JALR_5: begin
        // JALR
        wb_sel = `WB_PC4;
        dout_sel = `DOUT_DMEM;
        regwen = 1'b1;
    end

    `OPC_LUI_5: begin
        // LUI
        wb_sel = `WB_ALU;
        dout_sel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        wb_sel = `WB_ALU;
        dout_sel = `DOUT_DMEM;
        regwen = 1'b1;
    end
    
    endcase
end

endmodule