module program_counter #(
    parameter RESET_PC = 32'h4000_0000
) (
    input clk,
    input rst,
    input stall,
    input target_taken,
    input [31:0] target,
    input redirect_taken,
    input [31:0] redirect,
    output reg [31:0] pc_out
);

    reg [31:0] prev_pc;
    reg [31:0] curr_pc;
    reg [31:0] next_pc;

    reg override;
    reg [31:0] override_pc;
    reg [31:0] next_override_pc;

    always @(posedge clk) begin 
        if (rst) begin 
            curr_pc <= RESET_PC;
            prev_pc <= RESET_PC;
            override <= 1'b0;
        end else begin 
            if (!stall) begin 
                curr_pc <= next_pc + 32'd4;
                prev_pc <= curr_pc;
                override <= target_taken | redirect_taken;
            end else if (redirect_taken) begin 
                curr_pc <= redirect;
            end else if (target_taken) begin 
                curr_pc <= target;
            end
            override_pc <= next_override_pc;
        end 
    end   

    always @(*) begin 
        pc_out = curr_pc;
        next_pc = curr_pc;
        next_override_pc = override_pc;

        if (redirect_taken) begin
            next_pc = redirect;
            pc_out = redirect;
            next_override_pc = redirect;
        end else if (target_taken) begin 
            next_pc = target;
            pc_out = target;
            next_override_pc = target;
        end
  
        if (stall && !redirect_taken) begin 
            if (override) begin 
                pc_out = override_pc;
            end else begin 
                pc_out = prev_pc;
            end
        end
    end
endmodule
