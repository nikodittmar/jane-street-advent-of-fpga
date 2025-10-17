module mem_stage (
    input clk,
    input [31:0] ex_pc,
    input [31:0] ex_alu, 
    input [31:0] ex_rd2,
    input ex_br_suc, // Branch prediction success flag
    input [31:0] ex_inst,
    input [31:0] wb_wdata, // Forwarded result from WB stage
    input [31:0] wb_inst, // WB instruction for hazard detection
    output [31:0] mem_alu,
    output [31:0] mem_pc4,
    output [31:0] mem_dmem_dout, 
    output [31:0] mem_io_dout, 
    output [31:0] mem_inst,
    output [31:0] mem_addr,
    output [31:0] mem_imem_din,
    output [3:0] mem_imem_wea,
    output mem_imem_en
);
    wire mem_reg_rst;
    wire mem_reg_we;

    // MARK: DMem

    wire [13:0] mem_dmem_addr;
    wire [31:0] mem_dmem_din, mem_dmem_dout;
    wire [3:0] dmem_we;
    wire dmem_en;
    dmem dmem (
      .clk(clk),
      .en(mem_dmem_en),
      .we(mem_dmem_we),
      .addr(mem_dmem_addr),
      .din(mem_dmem_din),
      .dout(mem_dmem_dout)
    );

    // MARK: IO



    io io (
        .clk(clk),
        // ...
    );

    // MARK: Control Logic

    mem_control control (
        .inst(mem_inst),
        .pc(),
        .addr(),

        .imemrw(),
        .dmemrw(),
        .iorw(),
    );

    pipeline_reg pc_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_pc),

        .out(wb_pc)
    );
    
    pipeline_reg alu_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_alu),

        .out(wb_alu)
    );

    pipeline_reg inst_reg (
        .clk(clk),
        .rst(mem_reg_rst),
        .we(mem_reg_we),
        .in(mem_inst),

        .out(wb_inst)
    );
endmodule