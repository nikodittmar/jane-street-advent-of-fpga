module wb_stage (
    input clk,
    input [31:0] mem_alu,
    input [31:0] mem_pc4,
    input [31:0] mem_bios_dout, 
    input [31:0] mem_dmem_dout, 
    input [31:0] mem_io_dout, 
    input [31:0] mem_inst,
    output wb_regwen,
    output [31:0] wb_inst,
    output [31:0] wb_wdata
);

endmodule