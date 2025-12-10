`include "control_sel.vh"
`include "opcode.vh"

module id_control (
    input [31:0] inst,
    input [31:0] ex_inst,
    input [31:0] ex_fp_inst,
    input fpu_busy,

    output reg [2:0] imm_sel,
    output reg stall,
    output reg id_ex_stall,
    output reg fpu_valid
);

wire [4:0] opcode5 = inst[6:2];
wire [2:0] funct3 = inst[14:12];
wire [6:0] funct7 = inst[31:25];
wire [3:0] funct4 = inst[31:28];

wire [4:0] rs1 = inst[19:15];
wire has_rs1 = inst[6:2] != `OPC_AUIPC_5 && inst[6:2] != `OPC_LUI_5 && inst[6:2] != `OPC_JAL_5 && (inst[6:2] != `OPC_CSR_5 || inst[14:12] == `FNC_CSRRW) && rs1 != 5'b0 && inst[6:2] != `OPC_FP_MADD_5 && (inst[6:2] != `OPC_FP_5 || inst[31:25] == `FNC7_FP_MV_W_X || inst[31:25] == `FNC7_FP_CVT_S_W);

wire [4:0] rs2 = inst[24:20];
wire has_rs2 = (inst[6:2] == `OPC_ARI_RTYPE_5 || inst[6:2] == `OPC_STORE_5 || inst[6:2] == `OPC_BRANCH_5) && rs2 != 5'b0;

wire [4:0] fs1 = inst[19:15];
wire has_fs1 = inst[6:2] == `OPC_FP_MADD_5 || (inst[6:2] == `OPC_FP_5 && (inst[31:25] == `FNC7_FP_MV_X_W || inst[31:25] == `FNC7_FP_FSGNJ_S || inst[31:25] == `FNC7_FP_ADD));

wire [4:0] fs2 = inst[24:20];
wire has_fs2 = inst[6:2] == `OPC_FP_STORE_5 || inst[6:2] == `OPC_FP_MADD_5 || (inst[6:2] == `OPC_FP_5 && (inst[31:25] == `FNC7_FP_FSGNJ_S || inst[31:25] == `FNC7_FP_ADD));

wire [4:0] ex_rd = ex_inst[11:7];
wire ex_has_rd = ex_inst[6:2] != `OPC_STORE_5 && ex_inst[6:2] != `OPC_BRANCH_5 && ex_inst[6:2] != `OPC_CSR_5 && ex_inst[6:2] != `OPC_FP_LOAD_5 && ex_inst[6:2] != `OPC_FP_STORE_5 && ex_inst[6:2] != `OPC_FP_MADD_5 && (ex_inst[6:2] != `OPC_FP_5 || ex_inst[31:25] == `FNC7_FP_MV_X_W);

wire [4:0] ex_fd =  ex_inst[6:2] == `OPC_FP_LOAD_5 ? ex_inst[11:7] : ex_fp_inst[11:7];
wire ex_has_fd = ex_inst[6:2] == `OPC_FP_LOAD_5 || ex_fp_inst[6:2] == `OPC_FP_MADD_5 || (ex_fp_inst[6:2] == `OPC_FP_5 && ex_fp_inst[31:25] != `FNC7_FP_MV_X_W);

wire is_store = inst[6:2] == `OPC_STORE_5 || inst[6:2] == `OPC_FP_STORE_5;
wire ex_load_inst = ex_inst[6:2] == `OPC_LOAD_5 || ex_inst[6:2] == `OPC_FP_LOAD_5;

wire fpu_inst = inst[6:2] == `OPC_FP_5 || inst[6:2] == `OPC_FP_MADD_5;

always @(*) begin
    imm_sel = `IMM_DONT_CARE;
    stall = 1'b0;
    id_ex_stall = fpu_busy && fpu_inst;
    fpu_valid = fpu_inst && !fpu_busy;
   
    // hazards
    if (ex_has_rd && ((has_rs1 && rs1 == ex_rd) || (has_rs2 && rs2 == ex_rd))) begin
        stall = 1'b1;
    end

    // FPU hazards
    if (ex_has_fd && ((has_fs1 && fs1 == ex_fd) || (has_fs2 && fs2 == ex_fd))) begin
        stall = 1'b1;
    end

    case (opcode5)
    `OPC_ARI_ITYPE_5: begin
        imm_sel = `IMM_I;
    end
    `OPC_LOAD_5: begin
        imm_sel = `IMM_I;
    end
    `OPC_STORE_5: begin
        imm_sel = `IMM_S;
    end
    `OPC_BRANCH_5: begin 
        imm_sel = `IMM_B;
    end
    `OPC_JAL_5: begin
        // JAL
        imm_sel = `IMM_J;
    end
    `OPC_JALR_5: begin
        // JALR
        imm_sel = `IMM_I;
    end
    `OPC_LUI_5: begin
        // LUI
        imm_sel = `IMM_U;
    end
    `OPC_AUIPC_5: begin
        // AUIPC
        imm_sel = `IMM_U;
    end
    `OPC_CSR_5: begin 
        // CSR
        imm_sel = `IMM_CSR;
    end
    `OPC_FP_STORE_5: begin 
        // FSW
        imm_sel = `IMM_S;
    end
    `OPC_FP_LOAD_5: begin 
        // FLW
        imm_sel = `IMM_I;
    end
    endcase
end
endmodule