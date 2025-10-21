`include "control_sel.vh"

module if_control (
    input br_mispred,
    input target_taken,
    
    output reg [1:0] pc_sel = `PC_4
);

    always @(*) begin
        pc_sel = `PC_4;

        if (br_mispred) begin
            pc_sel = `PC_ALU;
        end else if (target_taken) begin 
            pc_sel = `PC_TGT;
        end
    end

endmodule