module fp_cvt (
    input clk,
    input  [31:0] in,
    output [31:0] res
);
    wire pre_res_sgn = in[31];
    wire [31:0] pre_un = pre_res_sgn ? (~in + 32'd1): in;
    wire pre_is_zero = (pre_un == 32'd0);

    wire [5:0] pre_un_lzc;

    lzc32 lzc (
        .in(pre_un),
        .count(pre_un_lzc)
    );

    wire [5:0] pre_msb_idx = 6'd31 - pre_un_lzc;

    reg [5:0] pack_msb_idx;
    reg [31:0] pack_un;
    reg pack_is_zero;
    reg pack_res_sgn;

    wire [5:0] pack_sh_r = (pack_msb_idx > 6'd23) ? (pack_msb_idx - 6'd23) : 6'd0;
    wire [5:0] pack_sh_l = (pack_msb_idx < 6'd23) ? (6'd23 - pack_msb_idx) : 6'd0;
    wire [31:0] pack_aligned = (pack_msb_idx >= 6'd23) ? (pack_un >> pack_sh_r) : (pack_un << pack_sh_l);

    wire [7:0] pack_res_exp = pack_is_zero ? 8'd0 : ({2'b00, pack_msb_idx} + 8'd127);
    wire [22:0] pack_res_man = pack_is_zero ? 23'd0 : pack_aligned[22:0];

    assign res = { pack_is_zero ? 1'b0 : pack_res_sgn, pack_res_exp, pack_res_man };

    always @(posedge clk) begin 
        pack_msb_idx <= pre_msb_idx;
        pack_un <= pre_un;
        pack_is_zero <= pre_is_zero;
        pack_res_sgn <= pre_res_sgn;
    end
endmodule
