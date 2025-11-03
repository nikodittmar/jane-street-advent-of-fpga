`include "control_sel.vh" 

module fpu (
    input [1:0] sel,
    input [31:0] fs1,
    input [31:0] fs2,
    input [31:0] fs3,
    input [31:0] rs1,
    output reg [31:0] res
);

    wire [31:0] mult_res;

    fp_mult multiplier (
        .a(fs1),
        .b(fs2),
        .res(mult_res)
    );

    wire [31:0] a = sel == `FPU_MADD ? mult_res : fs1;
    wire [31:0] b = sel == `FPU_MADD ? fs3 : fs2;
    wire [31:0] add_res;

    fp_add adder (
        .a(a),
        .b(b),
        .res(add_res)
    );

    wire [31:0] cvt_res;

    fp_cvt converter (
        .in(rs1),
        .res(cvt_res)
    );

    wire [31:0] sgn = { fs2[31], fs1[30:0] };

    always @(*) begin
        res = 32'b0;

        case(sel) 
        `FPU_ADD: res = add_res;
        `FPU_MADD: res = add_res;
        `FPU_CVT: res = cvt_res;
        `FPU_SGNJ: res = sgn;
        endcase
    end

endmodule