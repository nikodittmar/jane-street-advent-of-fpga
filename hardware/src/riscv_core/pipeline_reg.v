module pipeline_reg (
    input clk,
    input rst,
    input we,
    input [31:0] in,
    output reg [31:0] out
);
    always @(posedge clk) begin
        if (rst) begin
            out <= 32'b0;
        end else if (we) begin 
            out <= in;
        end
    end
endmodule