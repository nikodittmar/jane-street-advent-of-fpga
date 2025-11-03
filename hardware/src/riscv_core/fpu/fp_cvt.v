module fp_cvt (
    input  [31:0] in,
    output [31:0] res
);
    wire res_sgn = in[31];
    wire [31:0] un = res_sgn ? (~in + 32'd1): in;
    wire is_zero = (un == 32'd0);

    wire [5:0] un_lzc;

    lzc32 lzc (
        .in(un),
        .count(un_lzc)
    );

    wire [5:0] msb_idx = 6'd31 - un_lzc;

    wire [5:0] sh_r = (msb_idx > 6'd23) ? (msb_idx - 6'd23) : 6'd0;
    wire [5:0] sh_l = (msb_idx < 6'd23) ? (6'd23 - msb_idx) : 6'd0;
    wire [31:0] aligned = (msb_idx >= 6'd23) ? (un >> sh_r) : (un << sh_l);

    wire [7:0] res_exp = is_zero ? 8'd0 : ({2'b00, msb_idx} + 8'd127);
    wire [22:0] res_man = is_zero ? 23'd0 : aligned[22:0];

    assign res = { is_zero ? 1'b0 : res_sgn, res_exp, res_man };
endmodule
