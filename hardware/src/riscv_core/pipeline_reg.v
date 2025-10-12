module pipeline_reg (
    input clk,
    input we,
    input [31:0] in,
    output reg [31:0] out
);
    always @(posedge clk) begin
        if (we) out <= in;
    end
endmodule