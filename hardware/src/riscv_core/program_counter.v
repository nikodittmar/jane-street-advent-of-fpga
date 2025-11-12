module program_counter #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input stall,
    input flush,
    input [31:0] pc_in,
    output reg [31:0] pc_out
);

    reg [31:0] prev_pc;
    reg [31:0] pc;

    always @(posedge clk) begin 
        if (rst) begin
            pc <= RESET_PC;
        end else if (flush || !stall) begin
            prev_pc <= pc;
            pc <= pc_in;
        end
    end

    always @(*) begin
        if (stall && !flush) begin 
            pc_out = prev_pc;
        end else begin 
            pc_out = pc;
        end
    end

endmodule
