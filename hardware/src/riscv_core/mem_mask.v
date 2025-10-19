module mem_mask (
    input [31:0] din,
    input [3:0] mask,
    input un,
    output reg [31:0] dout
);

always @ (*) begin
    dout = 32'hxxxx_xxxx;
    case(mask)
    4'b0001: dout = un ? { 24'b0, din[7:0] } : { {24{din[7]}}, din[7:0] };
    4'b0010: dout = un ? { 24'b0, din[15:8] } : { {24{din[15]}}, din[15:8] };
    4'b0100: dout = un ? { 24'b0, din[23:16] } : { {24{din[23]}}, din[23:16] };
    4'b1000: dout = un ? { 24'b0, din[31:24] } : { {24{din[31]}}, din[31:24] };
    4'b0011: dout = un ? { 16'b0, din[15:0] } : { {16{din[15]}}, din[15:0] };
    4'b1100: dout = un ? { 16'b0, din[31:16] } : { {16{din[31]}}, din[31:16] };
    4'b1111: dout = din;
    endcase
end

endmodule