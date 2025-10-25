module program_counter #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input stall,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);

    reg buffered_pc;
    reg [31:0] pc_buf;

    always @(posedge clk) begin 
        if (rst) begin 
            pc_out <= RESET_PC;
        end else if (stall) begin
            pc_buf <= pc_in;
            pc_out <= pc_in;
            buffered_pc <= 1'b1;
        end else begin 
            if (buffered_pc) begin 
                buffered_pc <= 1'b0;
                pc_out <= pc_buf;
            end else begin 
                pc_out <= pc_in;
            end
        end
    end

endmodule