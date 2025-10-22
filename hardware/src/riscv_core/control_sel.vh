// List of control signal mappings
// Use `include "control_sel.vh" to use these

`ifndef CONTROL_SEL
`define CONTROL_SEL

// ***** IF STAGE *****

// PC sel
`define PC_MUX_NUM_INPUTS       3
`define PC_4                    2'b00
`define PC_ALU                  2'b01
`define PC_TGT                  2'b10

// ***** ID STAGE *****

// Nop instruction
`define NOP                     32'h0000_0013

// Instruction sel
`define INST_SEL_NUM_INPUTS     2
`define INST_IMEM               1'b0
`define INST_BIOS               1'b1

// Immediate generator sel
`define IMM_I                   3'b000 // I-type immediates
`define IMM_S                   3'b001 // S-type immediates
`define IMM_B                   3'b010 // B-type immediates
`define IMM_U                   3'b011 // U-type immediates
`define IMM_J                   3'b100 // J-type immediates
`define IMM_DONT_CARE           3'bxxx

// Target generator forwarding mux

`define TGT_GEN_FWD_NUM_INPUTS  4
`define TGT_GEN_FWD_NONE        2'b00
`define TGT_GEN_FWD_EX          2'b01
`define TGT_GEN_FWD_MEM         2'b10
`define TGT_GEN_FWD_WB          2'b11

// Target generator sel
`define TGT_GEN_JAL                 2'b00
`define TGT_GEN_JALR                2'b01
`define TGT_GEN_BR                  2'b10
`define TGT_GEN_DONT_CARE           2'bxx

// ***** EX STAGE *****

// Forwarding muxes
`define EX_FWD_NUM_INPUTS       3
`define EX_FWD_NONE             2'b00
`define EX_FWD_MEM              2'b01
`define EX_FWD_WB               2'b10

// BrUn
`define BRUN_DONT_CARE          1'bx

// ALU A input sel
`define A_NUM_INPUTS            2
`define A_REG                   1'b0
`define A_PC                    1'b1
`define A_DONT_CARE             1'bx

// ALU B input sel
`define B_NUM_INPUTS            2
`define B_REG                   1'b0
`define B_IMM                   1'b1
`define B_DONT_CARE             1'bx

// ALU sel
`define ALU_ADD                 4'b0000
`define ALU_SLL                 4'b0001
`define ALU_SLT                 4'b0010
`define ALU_XOR                 4'b0100
`define ALU_SRL                 4'b0101
`define ALU_OR                  4'b0110
`define ALU_AND                 4'b0111
`define ALU_SUB                 4'b1100
`define ALU_SRA                 4'b1101
`define ALU_BSEL                4'b1111
`define ALU_DONT_CARE           4'bxxxx

// CSR mux sel
`define CSR_MUX_NUM_INPUTS      2
`define CSR_IMM                 1'b0
`define CSR_RD1                 1'b1
`define CSR_DONT_CARE           1'bx

// ***** MEM STAGE *****

// Data in sel
`define DIN_NUM_INPUTS        2
`define DIN_WDATA             1'b0
`define DIN_RD2               1'b1
//`define DIN_FPU               2'b10
`define DIN_DONT_CARE         1'bx

// PC sel
`define MEM_PC_4                1'b0
`define MEM_PC_ALU              1'b1

// Memory nibble
`define ADDR_BIOS               4'b0100
`define ADDR_IO                 4'b1000
`define ADDR_DMEM               4'b00?1
`define ADDR_IMEM               4'b001?
`define ADDR_IDMEM              4'b00??

// Memory pack size
`define MEM_SIZE_BYTE           2'b00
`define MEM_SIZE_HALF           2'b01
`define MEM_SIZE_WORD           2'b10
`define MEM_SIZE_UNDEFINED      2'bxx

// Memory mapped I/O
`define MEM_IO_UART_CTRL        32'h800_0000
`define MEM_IO_UART_RDATA       32'h800_0004
`define MEM_IO_UART_TDATA       32'h800_0008
`define MEM_IO_CYCLE_CNT        32'h800_0010
`define MEM_IO_INST_CNT         32'h800_0014
`define MEM_IO_RST_CNT          32'h800_0018
`define MEM_IO_BR_INST_CNT      32'h800_001c
`define MEM_IO_BR_SUC_CNT       32'h800_0020

// ***** WB STAGE *****

// Dout out sel
`define DOUT_NUM_INPUTS         3
`define DOUT_BIOS               2'b00
`define DOUT_DMEM               2'b01
`define DOUT_IO                 2'b10
`define DOUT_DONT_CARE          2'bxx

// WB sel
`define WB_NUM_INPUTS           3
`define WB_PC4                  2'b00
`define WB_ALU                  2'b01
`define WB_MEM                  2'b10
`define WB_DONT_CARE            2'bxx

`endif // CONTROL_SEL