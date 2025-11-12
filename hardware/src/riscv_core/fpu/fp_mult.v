module fp_mult (
    input clk,
    input [31:0] a,
    input [31:0] b,
    output reg [31:0] res
);  

    reg [31:0] a_in;
    reg [31:0] b_in;

    wire [7:0] a_exp = a_in[30:23];
    wire [7:0] b_exp = b_in[30:23];

    wire [7:0] exp_sum = a_exp + b_exp;

    wire [23:0] a_man = { 1'b1, a_in[22:0] };
    wire [23:0] b_man = { 1'b1, b_in[22:0] };

    wire [47:0] man_product = a_man * b_man;

    wire msb = man_product[47];

    wire res_sgn = a_in[31] ^ b_in[31];
    wire [22:0] res_man = msb ? man_product[46:24] : man_product[45:23];
    wire [7:0] res_exp = msb ? exp_sum - 8'd126 : exp_sum - 8'd127;

    wire a_zero = a_in[30:0] == 31'b0;
    wire b_zero = b_in[30:0] == 31'b0;

    wire [31:0] mult_result;

    assign res = a_zero || b_zero ? 32'b0 : { res_sgn, res_exp, res_man };

    always @(posedge clk) begin
        a_in <= a;
        b_in <= b;
    end

endmodule