module mem_mask (
    input [31:0] din,
    input [3:0] mask,
    output reg [31:0] dout
);

// TODO: SV assertion that mask is valid

always @ (*) begin
    case(mask)
    4'b0001: dout = {24'b0, din[7:0]};
    4'b0010: dout = {24'b0, din[15:8]};
    4'b0100: dout = {24'b0, din[23:16]};
    4'b1000: dout = {24'b0, din[31:24]};
    4'b0011: dout = {16'b0, din[15:0]};
    4'b1100: dout = {16'b0, din[31:16]};
    4'b1111: dout = din;
    endcase

end

endmodule