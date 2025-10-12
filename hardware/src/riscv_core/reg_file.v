module reg_file (
    input clk,
    input we,
    input [4:0] ra1, ra2, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2
);
    // Only store x1-x31 (x0 not physically stored)
    reg [31:0] mem [1:31];

    // Asynchronous read
    assign rd1 = (ra1 == 5'b0) ? 32'b0 : mem[ra1];
    assign rd2 = (ra2 == 5'b0) ? 32'b0 : mem[ra2];

    // Synchronous write
    always @(posedge clk) begin
        if (we && wa != 5'b0) begin 
            mem[wa] <= wd;
        end
    end
endmodule
