module fp_add (
    input clk,
    input [31:0] a,
    input [31:0] b,
    output [31:0] res
);  

    // MARK: Decompose

    wire dcmp_a_sgn = a[31];
    wire dcmp_b_sgn = b[31];
    
    wire [7:0] dcmp_a_exp = a[30:23];
    wire [7:0] dcmp_b_exp = b[30:23];

    wire [23:0] dcmp_a_man = (a[22:0] == 23'b0 && dcmp_a_exp == 8'b0) ? 24'b0 : {1'b1, a[22:0]};
    wire [23:0] dcmp_b_man = (b[22:0] == 23'b0 && dcmp_b_exp == 8'b0) ? 24'b0 : {1'b1, b[22:0]};

    wire dcmp_a_larger = (dcmp_a_exp == dcmp_b_exp && dcmp_a_man > dcmp_b_man) || dcmp_a_exp > dcmp_b_exp;

    wire dcmp_lg_sgn = dcmp_a_larger ? dcmp_a_sgn : dcmp_b_sgn;
    wire dcmp_sm_sgn = dcmp_a_larger ? dcmp_b_sgn : dcmp_a_sgn;

    wire [7:0] dcmp_lg_exp = dcmp_a_larger ? dcmp_a_exp : dcmp_b_exp;
    wire [7:0] dcmp_sm_exp = dcmp_a_larger ? dcmp_b_exp : dcmp_a_exp;

    wire [23:0] dcmp_lg_man = dcmp_a_larger ? dcmp_a_man : dcmp_b_man;
    wire [23:0] dcmp_sm_man = dcmp_a_larger ? dcmp_b_man : dcmp_a_man;

    wire [7:0] dcmp_exp_diff = dcmp_lg_exp - dcmp_sm_exp;

    // MARK: Mantissa Shift

    reg [7:0] msh_exp_diff;
    reg msh_lg_sgn;
    reg msh_sm_sgn;
    reg [7:0] msh_lg_exp;
    reg [7:0] msh_sm_exp;
    reg [23:0] msh_lg_man;
    reg [23:0] msh_sm_man;

    wire msh_sticky = msh_exp_diff == 8'd0 ? 1'b0 : (msh_exp_diff >= 8'd24 ? |msh_sm_man : |(msh_sm_man & (24'hFFFFFF >> (24 - msh_exp_diff))));

    wire [23:0] msh_shifted_sm_man = msh_sm_man >> msh_exp_diff;

    // MARK: Mantissa Add

    reg madd_sticky;
    reg madd_lg_sgn;
    reg madd_sm_sgn;
    reg [7:0] madd_lg_exp;
    reg [7:0] madd_sm_exp;
    reg [23:0] madd_lg_man;
    reg [23:0] madd_sm_man;

    wire madd_add = (madd_lg_sgn == madd_sm_sgn);
    wire [23:0] madd_sm_op = (madd_lg_sgn != madd_sm_sgn) ? (madd_sm_man + (madd_sticky ? 24'd1 : 24'd0)) : madd_sm_man;

    wire [24:0] madd_man_sum = madd_add ? ({ 1'b0, madd_lg_man } + { 1'b0, madd_sm_op }) : ({ 1'b0, madd_lg_man } - { 1'b0, madd_sm_op });
    wire madd_carry = madd_man_sum[24];

    // MARK: Normalize

    reg norm_sgn;
    reg [7:0] norm_exp;
    reg [23:0] norm_man_sum;
    reg norm_carry;

    wire [4:0] norm_man_lzc;

    lzc24 lzc (
        .in(norm_man_sum[23:0]),
        .count(norm_man_lzc)
    );

    wire [23:0] norm_man = norm_man_sum[23:0] << norm_man_lzc;

    wire norm_zero_man = (norm_man_sum == 24'b0) && !norm_carry;
    
    wire res_sgn = norm_zero_man ? 1'b0 : norm_sgn;
    wire [7:0] res_exp = norm_zero_man ? 8'b0 : (norm_carry ? norm_exp + 8'b1 : norm_exp - { 3'b0, norm_man_lzc});
    wire [22:0] res_man = norm_carry ? norm_man_sum[23:1] : norm_man[22:0];

    assign res = { res_sgn, res_exp, res_man };

    always @(posedge clk) begin 
        msh_exp_diff <= dcmp_exp_diff;
        msh_lg_sgn <= dcmp_lg_sgn;
        msh_sm_sgn <= dcmp_sm_sgn;
        msh_lg_exp <= dcmp_lg_exp;
        msh_sm_exp <= dcmp_sm_exp;
        msh_lg_man <= dcmp_lg_man;
        msh_sm_man <= dcmp_sm_man;

        madd_sticky <= msh_sticky;
        madd_lg_sgn <= msh_lg_sgn;
        madd_sm_sgn <= msh_sm_sgn;
        madd_lg_exp <= msh_lg_exp;
        madd_sm_exp <= msh_sm_exp;
        madd_lg_man <= msh_lg_man;
        madd_sm_man <= msh_shifted_sm_man;

        norm_sgn <= madd_lg_sgn;
        norm_exp <= madd_lg_exp;
        norm_man_sum <= madd_man_sum[23:0];
        norm_carry <= madd_carry;
    end
endmodule
