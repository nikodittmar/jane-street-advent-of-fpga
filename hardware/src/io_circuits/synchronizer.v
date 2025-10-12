module synchronizer #(parameter WIDTH = 1) (
    input [WIDTH-1:0] async_signal,
    input clk,
    output [WIDTH-1:0] sync_signal
);
    reg [WIDTH-1:0] flip_1;
    reg [WIDTH-1:0] flip_2;

    always @(posedge clk) begin
        flip_1 <= async_signal;
        flip_2 <= flip_1;
    end
    
    assign sync_signal = flip_2;
endmodule
