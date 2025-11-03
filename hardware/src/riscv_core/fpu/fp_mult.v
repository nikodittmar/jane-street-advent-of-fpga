module fp_mult (
    input [31:0] a,
    input [31:0] b,
    output [31:0] res
);  

    wire [7:0] a_exp = a[30:23];
    wire [7:0] b_exp = b[30:23];

    wire [7:0] exp_sum = a_exp + b_exp;

    wire [23:0] a_man = { 1'b1, a[22:0] };
    wire [23:0] b_man = { 1'b1, b[22:0] };

    wire [47:0] man_product = a_man * b_man;

    wire msb = man_product[47];

    wire res_sgn = a[31] ^ b[31];
    wire [22:0] res_man = msb ? man_product[46:24] : man_product[45:23];
    wire [7:0] res_exp = msb ? exp_sum - 8'd126 : exp_sum - 8'd127;

    assign res = { res_sgn, res_exp, res_man };

endmodule