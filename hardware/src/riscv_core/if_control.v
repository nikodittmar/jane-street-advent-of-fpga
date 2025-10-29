`include "control_sel.vh"

module if_control (
    input rst,
    input [31:0] pc,
    input br_mispred,
    input target_taken,
    input stall,
    
    output reg [1:0] next_pc_sel,
    output reg [1:0] override_pc_sel,
    output reg bios_en
);

    always @(*) begin
        next_pc_sel = `PC_4;
        override_pc_sel = `PC_4;

        if (rst) begin 
            next_pc_sel = `PC_4;
            override_pc_sel = `PC_4;
        end else if (stall) begin 
            if (br_mispred) begin
                next_pc_sel = `PC_ALU;
            end else if (target_taken) begin 
                next_pc_sel = `PC_TGT;
            end
        end else begin 
            if (br_mispred) begin
                override_pc_sel = `PC_ALU;
            end else if (target_taken) begin 
                override_pc_sel = `PC_TGT;
            end
        end

        bios_en = pc[30] == `INST_BIOS;
    end

endmodule