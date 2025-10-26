`include "control_sel.vh"
`include "opcode.vh"

module mem_control (
    input [31:0] pc,
    input [31:0] addr,
    input [31:0] inst, 
    input [31:0] wb_inst, // next instruction for hazard detection

    output reg din_sel, // Forwarding MUX selector
    output reg [1:0] size, // Store size
    output reg br_inst, // Branch instruction flag
    output reg imem_en,
    output reg dmem_en,
    output reg bios_en,
    output reg io_en
);

wire [4:0] opcode5;
wire [2:0] funct3;
wire [6:0] funct7;

assign opcode5 = inst[6:2];
assign funct3 = inst[14:12];
assign funct7 = inst[31:25];

wire [4:0] rs2;
wire has_rs2;

wire [4:0] wb_rd;
wire wb_has_rd;

assign rs2 = inst[24:20];
assign has_rs2 = inst[6:0] == `OPC_ARI_RTYPE || inst[6:0] == `OPC_STORE || inst[6:0] == `OPC_BRANCH && rs2 != 5'b0;

assign wb_rd = wb_inst[11:7];
assign wb_has_rd = wb_inst[6:0] != `OPC_STORE && wb_inst[6:0] != `OPC_BRANCH && wb_inst[6:0] != `OPC_CSR;

always @ (*) begin
    din_sel = `DIN_DONT_CARE;
    size = `MEM_SIZE_UNDEFINED;
    br_inst = 1'b0;
    imem_en = 1'b0;
    dmem_en = 1'b0; 
    io_en = 1'b0;
    bios_en = 1'b0;

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
        end
        `FNC_SLL: begin
            // SLLI
        end
        `FNC_SLT: begin
            // SLTI
        end
        `FNC_SLTU: begin
            // SLTIU
        end
        `FNC_XOR: begin
            // XORI
        end
        `FNC_OR: begin
            // ORI
        end
        `FNC_AND: begin
            // ANDI
        end
        `FNC_SRL_SRA:
            case (inst[30])
            `FNC2_SRL: begin
                // SRLI
            end
            `FNC2_SRA: begin
                // SRAI
            end
            endcase
        endcase
    
    `OPC_LOAD_5: begin

        case (addr[31:28])
        `ADDR_IO: io_en = 1'b1;
        `ADDR_BIOS: bios_en = 1'b1;
        `ADDR_DMEM: dmem_en = 1'b1;
        `ADDR_MIRROR: dmem_en = 1'b1;
        endcase

        case (funct3)
        `FNC_LB: begin
            // LB
        end
        `FNC_LH: begin
            // LH
        end
        `FNC_LW: begin
            // LW
        end
        `FNC_LBU: begin
            // LBU
        end
        `FNC_LHU: begin
            // LHU
        end
        endcase
    end
    `OPC_STORE_5: begin

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

        if (has_rs2 && wb_has_rd && rs2 == wb_rd) begin
            din_sel = `DIN_WDATA;
        end else begin 
            din_sel = `DIN_RD2;
        end

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
    `OPC_BRANCH_5:
        case (funct3)
        `FNC_BEQ: begin
            // BEQ
            br_inst = 1'b1;
        end
        `FNC_BNE: begin
            // BNE
            br_inst = 1'b1;
        end
        `FNC_BLT: begin
            // BLT
            br_inst = 1'b1;
        end
        `FNC_BGE: begin
            // BGE
            br_inst = 1'b1;
        end
        `FNC_BLTU: begin
            // BLTU
            br_inst = 1'b1;
        end
        `FNC_BGEU: begin
            // BGEU
            br_inst = 1'b1;
        end
        endcase
    
    `OPC_JAL_5: begin
        // JAL
    end
    `OPC_JALR_5: begin
        // JALR
    end

    `OPC_LUI_5: begin
        // LUI
    end
    `OPC_AUIPC_5: begin
        // AUIPC
    end
    endcase
end

endmodule