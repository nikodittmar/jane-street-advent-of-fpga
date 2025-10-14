module mux #(
    parameter NUM_INPUTS = 2,
    parameter WIDTH = 32
) (
    input [NUM_INPUTS * WIDTH - 1: 0] in,
    input [$clog2(NUM_INPUTS) - 1:0] sel,
    output reg [WIDTH-1:0] out
);

    always @(*) begin 
        out = in[sel * WIDTH +: WIDTH];
    end

endmodule