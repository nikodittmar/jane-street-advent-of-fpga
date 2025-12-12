`include "control_sel.vh"
`include "opcode.vh"

module wb_control (
    input [31:0] inst, 
    input [31:0] fp_inst,
    input [31:0] addr,
    
    output reg [3:0] mask,
    output reg [1:0] wb_sel, 
    output reg [1:0] fp_wb_sel,
    output reg [1:0] dout_sel,
    output reg mask_un,
    output reg regwen,
    output reg fp_regwen
);

wire [4:0] opcode5 = inst[6:2];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];
wire [3:0] funct4 = inst[31:28];

wire [4:0] fp_opcode5 = fp_inst[6:2];
wire [2:0] fp_funct3 = fp_inst[14:12];
wire [6:0] fp_funct7 = fp_inst[31:25];
wire [3:0] fp_funct4 = fp_inst[31:28];

always @ (*) begin
    mask = 4'b0000;
    wb_sel = `WB_DONT_CARE;
    fp_wb_sel = `FP_WB_DONT_CARE;
    dout_sel = `DOUT_DONT_CARE;
    mask_un = 1'b0;
    regwen = 1'b0;
    fp_regwen = 1'b0;

    case (opcode5)
    `OPC_ARI_RTYPE_5: begin
        wb_sel = `WB_ALU;
        regwen = 1'b1;
    end
    `OPC_ARI_ITYPE_5: begin
        wb_sel = `WB_ALU;
        regwen = 1'b1;
    end
    `OPC_LOAD_5: begin
        wb_sel = `WB_MEM;
        regwen = 1'b1;

        case(addr[31:28])
        `ADDR_IO: dout_sel = `DOUT_IO;
        `ADDR_BIOS: dout_sel = `DOUT_BIOS;
        `ADDR_DMEM: dout_sel = `DOUT_DMEM;
        `ADDR_MIRROR: dout_sel = `DOUT_DMEM;
        endcase

        case (funct3)
        `FNC_LB: begin
            // LB
            case(addr[1:0])
            2'b00: mask = 4'b0001;
            2'b01: mask = 4'b0010;
            2'b10: mask = 4'b0100;
            2'b11: mask = 4'b1000;
            endcase
        end
        `FNC_LH: begin
            // LH
            case(addr[1:0])
            2'b00: mask = 4'b0011;
            2'b10: mask = 4'b1100;
            endcase
        end
        `FNC_LW: begin
            // LW
            mask = 4'b1111;
        end
        `FNC_LBU: begin
            // LBU
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
            case(addr[1:0])
            2'b00: mask = 4'b0011;
            2'b10: mask = 4'b1100;
            endcase

            mask_un = 1'b1;
        end
        endcase
    end
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
    `OPC_FP_LOAD_5: begin 
        // FLW
        fp_wb_sel = `FP_WB_MEM;
        fp_regwen = 1'b1;
        mask = 4'b1111;
        
        case(addr[31:28])
        `ADDR_IO: dout_sel = `DOUT_IO;
        `ADDR_BIOS: dout_sel = `DOUT_BIOS;
        `ADDR_DMEM: dout_sel = `DOUT_DMEM;
        `ADDR_MIRROR: dout_sel = `DOUT_DMEM;
        endcase
    end
    endcase

    case (fp_opcode5) 
    `OPC_FP_5: begin 
        case (funct4)
        `FNC4_FP_ADD: begin 
            // FADD
            fp_wb_sel = `FP_WB_FPU;
            fp_regwen = 1'b1;
        end
        `FNC4_FP_FSGNJ_S: begin 
            // FSGNJ.S
            fp_wb_sel = `FP_WB_FPU;
            fp_regwen = 1'b1;
        end
        `FNC4_FP_MV_X_W: begin 
            // FMV.X.W
            wb_sel = `WB_FPU;
            regwen = 1'b1;
        end
        `FNC4_FP_MV_W_X: begin 
            // FMV.W.X
            fp_wb_sel = `FP_WB_FPU;
            fp_regwen = 1'b1;
        end
        `FNC4_FP_CVT_S_W: begin 
            // FCVT.S.W
            fp_wb_sel = `FP_WB_FPU;
            fp_regwen = 1'b1;
        end
        endcase
    end
    `OPC_FP_MADD_5: begin 
        // FMADD
        fp_wb_sel = `FP_WB_FPU;
        fp_regwen = 1'b1;
    end
    endcase
end
endmodule