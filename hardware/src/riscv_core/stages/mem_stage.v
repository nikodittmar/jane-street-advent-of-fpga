module mem_stage (
    input clk,
    input [31:0] ex_pc,
    input [31:0] ex_alu, 
    input [31:0] ex_rd2,
    input [31:0] ex_inst,
    input [31:0] wb_wdata,
    output [31:0] mem_alu,
    output [31:0] mem_pc4,
    output [31:0] mem_bios_dout, 
    output [31:0] mem_dmem_dout, 
    output [31:0] mem_uart_dout, 
    output [31:0] mem_inst,
    output [31:0] mem_bios_addr,
    output [31:0] mem_imem_addr,
    output [31:0] mem_imem_wdata,
    output mem_imem_rw
);

endmodule