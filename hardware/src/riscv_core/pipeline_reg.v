module pipeline_reg #(
    parameter WIDTH = 32,
    parameter RESET_VAL = 32'b0
) (
    input clk,
    input rst,
    input we,
    input [WIDTH - 1:0] in,
    output reg [WIDTH - 1:0] out
);
    always @(posedge clk) begin
        if (rst) begin
            out <= RESET_VAL;
        end else if (we) begin 
            out <= in;
        end
    end
endmodule