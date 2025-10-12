module edge_detector #(
    parameter WIDTH = 1
)(
    input clk,
    input [WIDTH-1:0] signal_in,
    output reg [WIDTH-1:0] edge_detect_pulse
);
    reg [WIDTH-1:0] last;

    always @(posedge clk) begin
        edge_detect_pulse <= signal_in & ~last;
        last <= signal_in;
    end
endmodule
