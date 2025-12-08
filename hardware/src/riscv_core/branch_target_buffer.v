module branch_target_buffer #(
    parameter SIZE = 16
) (
    input rst,
    input clk,
    input [31:0] lookup_addr,

    input [31:0] update_addr,
    input [31:0] update_target,
    input update_en,
    input update_is_uncond,

    output reg [31:0] lookup_target,
    output reg lookup_hit,
    output reg lookup_is_uncond
);

    localparam IDX_SIZE = $clog2(SIZE);
    localparam TAG_SIZE = 30 - IDX_SIZE;

    // Target Buffer: { tag, target, is unconditional } 
    reg [TAG_SIZE + 31 + 1:0] tb [0:SIZE-1];
    reg [SIZE - 1:0] valid;

    reg [TAG_SIZE + 32:0] tb_entry;
    reg tb_entry_valid;

    wire [IDX_SIZE-1:0] lookup_idx = lookup_addr[IDX_SIZE+1:2];
    reg [TAG_SIZE-1:0] lookup_tag;

    wire [IDX_SIZE-1:0] update_idx = update_addr[IDX_SIZE+1:2];
    wire [TAG_SIZE-1:0] update_tag = update_addr[31-:TAG_SIZE];

    always @(posedge clk) begin
        if (rst) begin 
            valid <= 'b0;
            tb_entry <= 'b0;
            lookup_tag <= 'b0;
        end else begin
            tb_entry <= tb[lookup_idx]; 
            tb_entry_valid <= valid[lookup_idx];
            lookup_tag <= lookup_addr[31-:TAG_SIZE];

            if (update_en) begin 
                tb[update_idx] <= { update_tag, update_target, update_is_uncond };
                valid[update_idx] <= 1'b1;
            end
        end
    end

    always @(*) begin 
        if (tb_entry_valid) begin 
            lookup_is_uncond = tb_entry[0];
            lookup_target = tb_entry[32:1];
            lookup_hit = tb_entry[TAG_SIZE+32-:TAG_SIZE] == lookup_tag;
        end else begin 
            lookup_is_uncond = 1'b0;
            lookup_target = 32'b0;
            lookup_hit = 1'b0;
        end
    end

endmodule