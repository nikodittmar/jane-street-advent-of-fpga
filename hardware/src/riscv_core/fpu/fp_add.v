module fp_add (
    input [31:0] a,
    input [31:0] b,
    output [31:0] res
);
    wire a_sgn = a[31];
    wire b_sgn = b[31];
    
    wire [7:0] a_exp = a[30:23];
    wire [7:0] b_exp = b[30:23];

    wire [23:0] a_man = (a[22:0] == 23'b0 && a_exp == 8'b0) ? 24'b0 : {1'b1, a[22:0]};
    wire [23:0] b_man = (b[22:0] == 23'b0 && b_exp == 8'b0) ? 24'b0 : {1'b1, b[22:0]};

    wire a_larger = (a_exp == b_exp && a_man > b_man) || a_exp > b_exp;

    wire [7:0] lg_exp = a_larger ? a_exp : b_exp;
    wire [7:0] sm_exp = a_larger ? b_exp : a_exp;

    wire [7:0] exp_diff = lg_exp - sm_exp;

    wire [23:0] lg_man = a_larger ? a_man : b_man;
    wire [23:0] sm_raw = a_larger ? b_man : a_man;

    wire sticky = (exp_diff == 8'd0) ? 1'b0 : (exp_diff >= 8'd24) ? (|sm_raw) : (|(sm_raw & (24'hFFFFFF >> (24 - exp_diff))));

    wire [23:0] sm_man = (exp_diff >= 8'd24) ? 24'b0 : ((sm_raw >> exp_diff) + (((a_sgn != b_sgn) && sticky) ? 24'd1 : 24'd0));
    wire [24:0] man_sum = (a_sgn == b_sgn) ? ({1'b0,lg_man} + {1'b0,sm_man}) : ({1'b0,lg_man} - {1'b0,sm_man});
    
    wire zero_sum = man_sum == 25'b0;
        
    wire carry = man_sum[24];

    wire [4:0] man_lzc;

    lzc24 lzc (
        .in(man_sum[23:0]),
        .count(man_lzc)
    );

    wire [23:0] norm_man = man_sum[23:0] << man_lzc;

    wire res_sgn = zero_sum ? 1'b0 : (a_larger ? a_sgn : b_sgn);
    wire [7:0] res_exp = zero_sum ? 8'b0 : (carry ? lg_exp + 8'b1 : lg_exp - { 3'b0, man_lzc});
    wire [22:0] res_man = carry ? man_sum[23:1] : norm_man[22:0];

    assign res = { res_sgn, res_exp, res_man };
    
endmodule