module program_counter #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input stall,
    input flush,
    input in_valid,
    input [31:0] in,
    output reg [31:0] out
);

reg [31:0] prev_pc;
reg [31:0] pending_pc;
reg pending_valid;
reg prev_pc_valid;
reg [31:0] next_pc;

always @(posedge clk) begin
    if (rst) begin
        prev_pc <= RESET_PC;
        pending_pc <= 32'd0;
        pending_valid <= 1'b0;
        prev_pc_valid <= 1'b0;
    end else begin
        prev_pc <= next_pc;
        if (flush && in_valid) begin
            pending_valid <= 1'b0;
        end else if (stall) begin
            if (in_valid) begin
                pending_pc <= in;
                pending_valid <= 1'b1;
            end
        end else begin
            if (pending_valid) begin
                pending_valid <= 1'b0;
            end
        end
        if (!prev_pc_valid) begin
            prev_pc_valid <= 1'b1;
        end
    end
end

always @(*) begin
    if (rst) begin
        next_pc = RESET_PC;
    end else if (!prev_pc_valid) begin
        next_pc = prev_pc;
    end else if (flush && in_valid) begin
        next_pc = in;
    end else if (stall) begin
        next_pc = prev_pc;
    end else if (pending_valid) begin
        next_pc = pending_pc;
    end else if (in_valid) begin
        next_pc = in;
    end else begin
        next_pc = prev_pc + 32'd4;
    end
    out = next_pc;
end

endmodule