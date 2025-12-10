module gshare #(
    parameter SIZE = 32
) (
    input rst,
    input clk,
    input stall,
    input [31:0] predict_addr,
    
    input update_br_taken,
    input update_br_inst,
    input [$clog2(SIZE)-1:0] update_idx,
    input [1:0] update_sc,
    
    output reg [1:0] predict_sc,
    output reg [$clog2(SIZE)-1:0] predict_idx,
    output reg predict_taken
);

    reg [$clog2(SIZE)-1:0] ghr;

    (* ram_style = "block" *) reg [1:0] pht [0:SIZE-1];
    reg [SIZE-1:0] valid;

    reg [1:0] pht_entry;
    reg pht_entry_valid;

    wire [$clog2(SIZE)-1:0] lookup_idx = ghr ^ predict_addr[$clog2(SIZE)+1:2];

    always @(posedge clk) begin 
        if (rst) begin 
            ghr <= 'b0;
            valid <= 'b0;
            pht_entry <= 'b0;
            pht_entry_valid <= 'b0;
        end else begin
            if (!stall) begin
                pht_entry <= pht[lookup_idx];
                pht_entry_valid <= valid[lookup_idx];
                predict_idx <= lookup_idx;
            end
            if (update_br_inst) begin 
                ghr <= { ghr[$clog2(SIZE)-2:0], update_br_taken};
                valid[update_idx] <= 1'b1;
                
                if (update_br_taken && update_sc < 2'b11) begin 
                    pht[update_idx] <= update_sc + 2'b1;
                end else if (!update_br_taken && update_sc > 2'b00) begin 
                    pht[update_idx] <= update_sc - 2'b1;
                end
            end
        end
    end

    always @(*) begin 
        if (pht_entry_valid) begin 
            predict_taken = pht_entry > 2'b01;
            predict_sc = pht_entry;
        end else begin 
            predict_taken = 1'b0;
            predict_sc = 2'b01;
        end
    end

endmodule