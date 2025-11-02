`include "control_sel.vh" 

module fpu (
    input [1:0] sel,
    input [31:0] op1,
    input [31:0] op2,
    input [31:0] op3,
    output [31:0] res
);

wire [7:0] dcmp_exp1 = op1[30:23];
wire [7:0] dcmp_exp2 = op2[30:23];
wire [7:0] dcmp_exp3 = op3[30:23];

wire [22:0] dcmp_man1 = op1[22:0];
wire [22:0] dcmp_man2 = op2[22:0];
wire [22:0] dcmp_man3 = op3[22:0];

wire dcmp_sign1 = op1[31];
wire dcmp_sign2 = op2[31];
wire dcmp_sign3 = op3[31];

wire [47:0] mult_prod = {1'b1, dcmp_man1} * {1'b1, dcmp_man2};
wire [7:0] mult_exp = dcmp_exp1 + dcmp_exp2 - 8'd127 + { 7'b0, mult_prod[47]};
wire [22:0] mult_prod_trunc = mult_prod[47] ? mult_prod[47:25] : mult_prod[46:24];

wire add_sgn1 = sel == `FPU_MADD ?  op1[31] ^ op2[31] : op1[31];
wire add_sgn2 = sel == `FPU_MADD ? op3[31] : op2[31];

wire [7:0] add_exp1 = sel == `FPU_MADD ? mult_exp : dcmp_exp1;
wire [7:0] add_exp2 = sel == `FPU_MADD ? dcmp_exp3 : dcmp_exp2;

wire [22:0] add_man1 = sel == `FPU_MADD ? mult_prod_trunc : dcmp_man1;
wire [22:0] add_man2 = sel == `FPU_MADD ? dcmp_man3 : dcmp_man2;

wire [7:0] sm_exp = ((add_exp1 == add_exp2 && add_man1 < add_man2) || add_exp1 < add_exp2) ? add_exp1 : add_exp2;
wire [7:0] lg_exp = ((add_exp1 == add_exp2 && add_man1 < add_man2) || add_exp1 < add_exp2) ? add_exp2 : add_exp1;

wire [22:0] sm_man = ((add_exp1 == add_exp2 && add_man1 < add_man2) || add_exp1 < add_exp2) ? add_man1 : add_man2;
wire [22:0] lg_man = ((add_exp1 == add_exp2 && add_man1 < add_man2) || add_exp1 < add_exp2) ? add_man2 : add_man1;

wire [7:0] diff = lg_exp - sm_exp;

wire [22:0] shift_man = sm_man << diff;

wire [24:0] sum_man = add_sgn1 == add_sgn2 ? {1'b1, lg_man} + {1'b1, sm_man} : {1'b1, lg_man} - {1'b1, sm_man};

wire [4:0] lzc;

lzc lzc_inst (
    .in(sum_man),
    .count(lzc)
);

wire final_sgn = ((add_exp1 == add_exp2 && add_man1 < add_man2) || add_exp1 < add_exp2) ? add_sgn1 : add_sgn2;
wire [7:0] final_exp = lg_exp + {3'b0, lzc} + {7'b0, sum_man[24]};
wire [23:0] final_man = sum_man[23:0] << lzc;

assign res = {final_sgn, final_exp, final_man[23:1]};

endmodule