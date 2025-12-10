`include "control_sel.vh"
`include "opcode.vh"

module id_control (
    input [31:0] inst,
    input [31:0] ex_inst,
    input [31:0] ex_fp_inst,
    input fpu_busy,

    output reg [2:0] imm_sel,
    output stall,
    output id_ex_stall,
    output fpu_valid
);

    wire [4:0] opcode5 = inst[6:2];
    wire [2:0] funct3 = inst[14:12];
    wire [3:0] funct4 = inst[31:28];

    wire [4:0] rs1 = inst[19:15];
    wire [4:0] rs2 = inst[24:20];
    wire [4:0] fs1 = inst[19:15];
    wire [4:0] fs2 = inst[24:20];

    wire [4:0] ex_opcode5 = ex_inst[6:2];
    wire [6:0] ex_funct7 = ex_inst[31:25];
    wire [4:0] ex_rd = ex_inst[11:7];

    wire [4:0] ex_fp_opcode5 = ex_fp_inst[6:2];
    wire [6:0] ex_fp_funct7 = ex_fp_inst[31:25];

    wire op_ari_itype = (opcode5 == `OPC_ARI_ITYPE_5);
    wire op_ari_rtype = (opcode5 == `OPC_ARI_RTYPE_5);
    wire op_load = (opcode5 == `OPC_LOAD_5);
    wire op_store = (opcode5 == `OPC_STORE_5);
    wire op_branch = (opcode5 == `OPC_BRANCH_5);
    wire op_jal = (opcode5 == `OPC_JAL_5);
    wire op_jalr = (opcode5 == `OPC_JALR_5);
    wire op_lui = (opcode5 == `OPC_LUI_5);
    wire op_auipc = (opcode5 == `OPC_AUIPC_5);
    `ifndef SYNTHESIS
        wire op_csr = (opcode5 == `OPC_CSR_5);
    `endif
    wire op_fp_load = (opcode5 == `OPC_FP_LOAD_5);
    wire op_fp_store = (opcode5 == `OPC_FP_STORE_5);
    wire op_fp = (opcode5 == `OPC_FP_5);
    wire op_fp_madd = (opcode5 == `OPC_FP_MADD_5);

    wire f4_fp_mv_w_x = (funct4 == `FNC4_FP_MV_W_X);
    wire f4_fp_cvt_s_w = (funct4 == `FNC4_FP_CVT_S_W);
    wire f4_fp_mv_x_w = (funct4 == `FNC4_FP_MV_X_W);
    wire f4_fp_fsgnj_s = (funct4 == `FNC4_FP_FSGNJ_S);
    wire f4_fp_add = (funct4 == `FNC4_FP_ADD);

    wire ex_op_store = (ex_opcode5 == `OPC_STORE_5);
    wire ex_op_branch = (ex_opcode5 == `OPC_BRANCH_5);
    `ifndef SYNTHESIS
        wire ex_op_csr = (ex_opcode5 == `OPC_CSR_5);
    `endif
    wire ex_op_fp_load = (ex_opcode5 == `OPC_FP_LOAD_5);
    wire ex_op_fp_store = (ex_opcode5 == `OPC_FP_STORE_5);
    wire ex_op_fp = (ex_opcode5 == `OPC_FP_5);
    wire ex_op_fp_madd = (ex_opcode5 == `OPC_FP_MADD_5);

    wire ex_f4_fp_mv_x_w = (ex_funct7 == `FNC7_FP_MV_X_W);

    wire ex_fp_op_fp = (ex_fp_opcode5 == `OPC_FP_5);
    wire ex_fp_op_fp_madd = (ex_fp_opcode5 == `OPC_FP_MADD_5);
    wire ex_fp_f7_mv_x_w = (ex_fp_funct7 == `FNC7_FP_MV_X_W);

    `ifndef SYNTHESIS
        wire has_rs1 = !op_auipc & !op_lui & !op_jal & !op_fp_madd & ( !op_csr | (funct3 == `FNC_CSRRW) ) & ( !op_fp  | (f4_fp_mv_w_x | f4_fp_cvt_s_w) ) & (rs1 != 5'd0);
    `else    
        wire has_rs1 = !op_auipc & !op_lui & !op_jal & !op_fp_madd & ( !op_fp  | (f4_fp_mv_w_x | f4_fp_cvt_s_w) ) & (rs1 != 5'd0);
    `endif

    wire has_rs2 = (op_ari_rtype | op_store | op_branch) & (rs2 != 5'd0);

    wire has_fs1 = op_fp_madd | (op_fp & (f4_fp_mv_x_w | f4_fp_fsgnj_s | f4_fp_add));
    wire has_fs2 = op_fp_store | op_fp_madd  | (op_fp & (f4_fp_fsgnj_s | f4_fp_add));

    `ifndef SYNTHESIS
        wire ex_has_rd = !( ex_op_store | ex_op_branch | ex_op_csr | ex_op_fp_load | ex_op_fp_store | ex_op_fp_madd | (ex_op_fp & !ex_f4_fp_mv_x_w) );
    `else
        wire ex_has_rd = !( ex_op_store | ex_op_branch | ex_op_fp_load | ex_op_fp_store | ex_op_fp_madd | (ex_op_fp & !ex_f4_fp_mv_x_w) );
    `endif

    wire [4:0] ex_fd = ex_op_fp_load ? ex_inst[11:7] : ex_fp_inst[11:7];

    wire ex_has_fd = ex_op_fp_load | ex_fp_op_fp_madd | (ex_fp_op_fp & !ex_fp_f7_mv_x_w);

    wire is_store = op_store | op_fp_store;
    wire ex_load_inst = (ex_opcode5 == `OPC_LOAD_5) | ex_op_fp_load;

    wire fpu_inst = op_fp | op_fp_madd;

    wire rs_hazard = ex_has_rd & ( (has_rs1 & (rs1 == ex_rd)) | (has_rs2 & (rs2 == ex_rd)) );

    wire fs_hazard = ex_has_fd & ( (has_fs1 & (fs1 == ex_fd)) | (has_fs2 & (fs2 == ex_fd)) );

    assign stall = rs_hazard | fs_hazard;
    assign id_ex_stall = fpu_busy & fpu_inst;
    assign fpu_valid = fpu_inst & ~fpu_busy;

    always @(*) begin
        imm_sel = `IMM_DONT_CARE;

        case (opcode5)
            `OPC_ARI_ITYPE_5: imm_sel = `IMM_I;
            `OPC_LOAD_5: imm_sel = `IMM_I;
            `OPC_STORE_5: imm_sel = `IMM_S;
            `OPC_BRANCH_5: imm_sel = `IMM_B;
            `OPC_JAL_5: imm_sel = `IMM_J;
            `OPC_JALR_5: imm_sel = `IMM_I;
            `OPC_LUI_5: imm_sel = `IMM_U;
            `OPC_AUIPC_5: imm_sel = `IMM_U;
            `OPC_FP_STORE_5: imm_sel = `IMM_S; // FSW
            `OPC_FP_LOAD_5: imm_sel = `IMM_I; // FLW
            default: imm_sel = `IMM_DONT_CARE;
        endcase
    end

endmodule
