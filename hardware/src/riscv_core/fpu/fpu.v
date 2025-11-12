`include "control_sel.vh" 

module fpu (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    input [2:0] sel,
    input input_valid,
    output reg [31:0] res,
    output reg busy
);

    wire [31:0] mult_res;

    fp_mult multiplier (
        .clk(clk),
        .a(a),
        .b(b),
        .res(mult_res)
    );
    
    wire [31:0] add_a = sel == `FPU_MADD ? mult_res : a;
    wire [31:0] add_b = sel == `FPU_MADD ? c : b;
    wire [31:0] add_res;

    fp_add adder (
        .clk(clk),
        .a(add_a),
        .b(add_b),
        .res(add_res)
    );

    wire [31:0] cvt_res;

    fp_cvt converter (
        .clk(clk),
        .in(a),
        .res(cvt_res)
    );

    wire [31:0] sgnj_res = { b[31], a[30:0] };

    reg [3:0] op_lat;

    reg [3:0] cnt;
    reg [3:0] next_cnt;

    always @(posedge clk) begin 
        if (rst) begin 
            cnt <= 1'b0;
        end else begin 
            cnt <= next_cnt;
        end
    end

    always @(*) begin
        res = 32'b0;
        op_lat = 4'b0;

        case(sel) 
        `FPU_ASEL: begin 
            res = a;
            op_lat = 4'd0;
        end
        `FPU_BSEL: begin 
            res = b;
            op_lat = 4'd0;
        end
        `FPU_ADD: begin 
            res = add_res;
            op_lat = 4'd3;
        end
        `FPU_MADD: begin 
            res = add_res;
            op_lat = 4'd4;
        end
        `FPU_CVT: begin 
            res = cvt_res;
            op_lat = 4'd1;
        end
        `FPU_SGNJ: begin 
            res = sgnj_res;
            op_lat = 4'd0;
        end
        endcase

        next_cnt = input_valid ? 4'b1 : cnt + 1;
        busy = op_lat != 4'b0 && (input_valid | cnt < op_lat);
    end
endmodule
