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
`define IMM_DONT_CARE           3'b000

// Target generator sel
`define TGT_GEN_JAL                 1'b0
`define TGT_GEN_BR                  1'b1
`define TGT_GEN_DONT_CARE           1'b0

// ***** EX STAGE *****

// BrUn
`define BRUN_DONT_CARE          1'b0

// FPU A input sel
`define FP_A_NUM_INPUTS         2
`define FP_A_FP_REG             1'b0
`define FP_A_REG                1'b1
`define FP_A_DONT_CARE          1'b0

// ALU A input sel
`define A_NUM_INPUTS            2
`define A_REG                   1'b0
`define A_PC                    1'b1
`define A_DONT_CARE             1'b0

// ALU B input sel
`define B_NUM_INPUTS            2
`define B_REG                   1'b0
`define B_IMM                   1'b1
`define B_DONT_CARE             1'b0

// ALU sel
`define ALU_ADD                 4'b0000
`define ALU_SLL                 4'b0001
`define ALU_SLT                 4'b0010
`define ALU_SLTU                4'b0011
`define ALU_XOR                 4'b0100
`define ALU_SRL                 4'b0101
`define ALU_OR                  4'b0110
`define ALU_AND                 4'b0111
`define ALU_SUB                 4'b1100
`define ALU_SRA                 4'b1101
`define ALU_A_PLUS_4            4'b1110
`define ALU_BSEL                4'b1111
`define ALU_DONT_CARE           4'b0000

// CSR mux sel
`define CSR_MUX_NUM_INPUTS      2
`define CSR_IMM                 1'b0
`define CSR_RD1                 1'b1
`define CSR_DONT_CARE           1'b0

// PC redirect sel
`define REDIR_ALU               1'b0
`define REDIR_PC4               1'b1
`define REDIR_DONT_CARE         1'b0

// ***** MEM STAGE *****

// Data in sel
`define DIN_NUM_INPUTS        2
`define DIN_RD2               1'b0
`define DIN_FPU               1'b1
`define DIN_DONT_CARE         1'b0

// PC sel
`define MEM_PC_4                1'b0
`define MEM_PC_ALU              1'b1

// Memory nibble
`define ADDR_BIOS               4'b0100
`define ADDR_IO                 4'b1000
`define ADDR_DMEM               4'b0001
`define ADDR_IMEM               4'b0010
`define ADDR_MIRROR             4'b0011

// Memory pack size
`define MEM_SIZE_BYTE           2'b00
`define MEM_SIZE_HALF           2'b01
`define MEM_SIZE_WORD           2'b10
`define MEM_SIZE_UNDEFINED      2'b11 // Doesn't work if it is 00?

// Memory mapped I/O
`define MEM_IO_UART_CTRL        32'h8000_0000
`define MEM_IO_UART_RDATA       32'h8000_0004
`define MEM_IO_UART_TDATA       32'h8000_0008
`define MEM_IO_CYCLE_CNT        32'h8000_0010
`define MEM_IO_INST_CNT         32'h8000_0014
`define MEM_IO_RST_CNT          32'h8000_0018
`define MEM_IO_BR_INST_CNT      32'h8000_001c
`define MEM_IO_BR_SUC_CNT       32'h8000_0020

// ***** WB STAGE *****

// Dout out sel
`define DOUT_NUM_INPUTS         3
`define DOUT_BIOS               2'b00
`define DOUT_DMEM               2'b01
`define DOUT_IO                 2'b10
`define DOUT_DONT_CARE          2'b00

// WB sel
`define WB_NUM_INPUTS           4
`define WB_PC4                  2'b00
`define WB_ALU                  2'b01
`define WB_MEM                  2'b10
`define WB_FPU                  2'b11
`define WB_DONT_CARE            2'b00

// ***** FLOATING POINT *****

// FPU sel
`define FPU_ADD                 3'b001
`define FPU_MADD                3'b010
`define FPU_CVT                 3'b011
`define FPU_SGNJ                3'b100
`define FPU_ASEL                3'b101
`define FPU_BSEL                3'b110
`define FPU_DONT_CARE           3'b000

`endif // CONTROL_SEL