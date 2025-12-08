module branch_predictor (
    input rst,
    input clk,
    input [31:0] if_addr,
    input [31:0] ex_addr,
    input [31:0] ex_target,
    input ex_target_valid,
    input ex_br_inst,
    input ex_is_uncond,
    input ex_br_taken,
    input wb_flush,
    input id_stall,

    output [31:0] id_target,
    output id_target_taken
);

    wire [5:0] predict_idx;
    wire [1:0] predict_sc;
    wire predict_taken;

    reg [5:0] update_idx;
    reg [1:0] update_sc;

    wire update_br_inst = !wb_flush && ex_br_inst;

    gshare gs (
        .rst(rst),
        .clk(clk),
        .predict_addr(if_addr),

        .update_br_taken(ex_br_taken),
        .update_br_inst(update_br_inst),
        .update_idx(update_idx),
        .update_sc(update_sc),
        
        .predict_sc(predict_sc),
        .predict_idx(predict_idx),
        .predict_taken(predict_taken)
    );

    wire lookup_hit;
    wire lookup_is_uncond;
    wire update_en = !wb_flush && ex_target_valid;

    branch_target_buffer btb (
        .rst(rst),
        .clk(clk),
        .lookup_addr(if_addr),
        .update_addr(ex_addr),
        .update_target(ex_target),
        .update_en(update_en),
        .update_is_uncond(ex_is_uncond),

        .lookup_target(id_target),
        .lookup_hit(lookup_hit),
        .lookup_is_uncond(lookup_is_uncond)
    );

    always @(posedge clk) begin 
        if (!id_stall) begin
            update_idx <= predict_idx;
            update_sc <= predict_sc;
        end
    end

    assign id_target_taken = lookup_hit && (lookup_is_uncond || predict_taken);

endmodule