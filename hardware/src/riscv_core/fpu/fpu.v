`include "control_sel.vh" 

module fpu (
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    input [2:0] sel,
    output reg [31:0] res,
    output reg busy
);

    wire [31:0] mult_res;

    fp_mult multiplier (
        .a(a),
        .b(b),
        .res(mult_res)
    );

    wire [31:0] add_a = sel == `FPU_MADD ? mult_res : a;
    wire [31:0] add_b = sel == `FPU_MADD ? c : b;
    wire [31:0] add_res;

    fp_add adder (
        .a(add_a),
        .b(add_b),
        .res(add_res)
    );

    wire [31:0] cvt_res;

    fp_cvt converter (
        .in(a),
        .res(cvt_res)
    );

    wire [31:0] sgnj_res = { b[31], a[30:0] };

    always @(*) begin
        res = 32'b0;
        busy = 1'b0;

        case(sel) 
        `FPU_ASEL: res = a;
        `FPU_BSEL: res = b;
        `FPU_ADD: res = add_res;
        `FPU_MADD: res = add_res;
        `FPU_CVT: res = cvt_res;
        `FPU_SGNJ: res = sgnj_res;
        endcase
    end

endmodule