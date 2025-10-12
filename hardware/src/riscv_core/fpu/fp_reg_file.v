module fp_reg_file (
    input clk,
    input we,
    input [4:0] ra1, ra2, ra3, wa,
    input [31:0] wd,
    output [31:0] rd1, rd2, rd3
);
    reg [31:0] mem [0:31];

    // Asynchronous read
    assign rd1 = mem[ra1];
    assign rd2 = mem[ra2];
    assign rd3 = mem[ra3];

    // Synchronous write
    always @(posedge clk) begin
        if (we) begin 
            mem[wa] <= wd;
        end
    end
endmodule
