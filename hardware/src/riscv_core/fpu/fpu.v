`include "control_sel.vh" 

module fpu (
    input clk,
    input rst,
    input [31:0] a,
    input [31:0] b,
    input [31:0] c,
    input [2:0] sel,
    input input_valid,
    input [31:0] inst_in,
    
    output reg [31:0] res,
    output reg busy,
    output reg [31:0] inst_out
);

    reg [2:0] int_sel;
    reg [2:0] next_int_sel;
    reg [2:0] fpu_sel;

    reg [31:0] int_a;
    reg [31:0] int_b;
    reg [31:0] int_c;

    reg [31:0] next_int_a;
    reg [31:0] next_int_b;
    reg [31:0] next_int_c;



    wire [31:0] mult_res;

    fp_mult multiplier (
        .clk(clk),
        .a(next_int_a),
        .b(next_int_b),
        .res(mult_res)
    );
    
    wire [31:0] add_a = fpu_sel == `FPU_MADD ? mult_res : next_int_a;
    wire [31:0] add_b = fpu_sel == `FPU_MADD ? next_int_c : next_int_b;
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
        .in(next_int_a),
        .res(cvt_res)
    );

    wire [31:0] sgnj_res = { next_int_b[31], next_int_a[30:0] };

    reg [3:0] op_lat;

    reg [3:0] cnt;
    reg [3:0] next_cnt;
    reg [31:0] inst;

    always @(posedge clk) begin 
        if (rst) begin 
            cnt <= 1'b0;
            inst <= 32'h0000_0013;
            int_sel <= `FPU_DONT_CARE;
        end else begin 
            cnt <= next_cnt;

            if (input_valid && op_lat > 4'd0) begin 
                inst <= inst_in;
            end else if (!busy) begin
                inst <= 32'h0000_0013;
            end

            int_a = next_int_a;
            int_b = next_int_b;
            int_c = next_int_c;

            
            int_sel <= next_int_sel;
        end
    end

    always @(*) begin
        res = 32'b0;
        op_lat = 4'b0;
        next_int_sel = input_valid ? sel : busy ? int_sel : 4'd0;
        fpu_sel = input_valid ? sel : int_sel;

        next_int_a = input_valid ? a : int_a;
        next_int_b = input_valid ? b : int_b;
        next_int_c = input_valid ? c : int_c;


        case(fpu_sel) 
        `FPU_ASEL: begin 
            res = a;
            op_lat = 4'd0;
        end
        `FPU_ADD: begin 
            res = add_res;
            op_lat = 4'd4;
        end
        `FPU_MADD: begin 
            res = add_res;
            op_lat = 4'd5;
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
        inst_out = input_valid ? inst_in : inst;
    end
endmodule
