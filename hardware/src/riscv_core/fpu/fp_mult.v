module fp_mult (
    input clk,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] res
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

    wire a_zero = a[30:0] == 31'b0;
    wire b_zero = b[30:0] == 31'b0;

    wire [31:0] mult_result;

    assign mult_result = a_zero || b_zero ? 32'b0 : { res_sgn, res_exp, res_man };

    always @(posedge clk) begin
        res <= mult_result;
    end

endmodule