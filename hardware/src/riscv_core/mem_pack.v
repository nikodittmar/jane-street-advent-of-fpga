`include "control_sel.vh"

module mem_pack (
    input [31:0] in,
    input [1:0] offset,
    input [1:0] size,

    output reg [31:0] out,
    output reg [3:0] we
); 

    always @(*) begin
        out = 32'b0;
        we = 4'b0;

        case (size)
        `MEM_SIZE_BYTE: begin
            case (offset)
            2'b00: begin 
                out = { 24'hxxxx_xx, in[7:0] };
                we = 4'b0001;
            end
            2'b01: begin 
                out = { 16'hxxxx, in[7:0], 8'hxx };
                we = 4'b0010;
            end
            2'b10: begin 
                out = { 8'hxx, in[7:0], 16'hxxx };
                we = 4'b0100;
            end
            2'b11: begin 
                out = { in[7:0], 24'hxxxx_xx };
                we = 4'b1000;
            end
            endcase
        end
        `MEM_SIZE_HALF: begin
            case (offset)
            2'b00: begin 
                out = { 16'hxxxx, in[15:0] };
                we = 4'b0011;
            end
            2'b10: begin 
                out = { in[15:0], 16'hxxxx };
                we = 4'b1100;
            end
            endcase
        end
        `MEM_SIZE_WORD: begin
            out = in;
            we = 4'b1111;
        end
        endcase
    end
endmodule