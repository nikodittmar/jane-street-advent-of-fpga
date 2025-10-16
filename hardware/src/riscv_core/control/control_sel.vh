// List of control signal mappings
// Use `include "control_sel.vh" to use these

`ifndef CONTROL_SEL
`define CONTROL_SEL

// ***** IF STAGE *****

// PC sel
`define PC_4                    2'b00
`define PC_ALU                  2'b01
`define PC_JUMP                 2'b10

// Instruction sel
`define INST_BIOS               1'b0
`define INST_IMEM               1'b1

// ***** ID STAGE *****

// Instruction sel
`define INST_SEL_NUM_INPUTS     2
`define INST_BIOS               1'b0
`define INST_IMEM               1'b1

// Immediate generator sel
`define IMM_I                   3'b000 // I-type immediates
`define IMM_S                   3'b001 // S-type immediates
`define IMM_B                   3'b010 // B-type immediates
`define IMM_U                   3'b011 // U-type immediates
`define IMM_J                   3'b100 // J-type immediates
`define IMM_DONT_CARE           3'bxxx

// Forwarding mux
`define ID_FWD_NUM_INPUTS       4
`define ID_FWD_NONE             2'b00
`define ID_FWD_EX               2'b01
`define ID_FWD_MEM              2'b10
`define ID_FWD_WB               2'b11

// Target generator sel
`define TGT_JAL                 2'b00
`define TGT_JALR                2'b01
`define TGT_BR                  2'b10
`define TGT_DONT_CARE           2'bxx

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

// ALU B input sel
`define B_NUM_INPUTS            2
`define B_REG                   1'b0
`define B_IMM                   1'b1

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

// ***** MEM STAGE *****

// Wdata sel
`define WDATA_MEM               2'b00
`define WDATA_ALU               2'b01
`define WDATA_FPU               2'b10
`define WDATA_DONT_CARE         2'bxx

// IORW sel
`define IO_READ     1'b0
`define IO_WRITE    1'b1

// ***** WB STAGE *****

// Dout out sel
`define DOUT_NUM_INPUTS         3
`define DOUT_BIOS               2'b00
`define DOUT_DMEM               2'b01
`define DOUT_UART               2'b10

// WB sel
`define WB_NUM_INPUTS           3
`define WB_PC4                  2'b00
`define WB_ALU                  2'b01
`define WB_MEM                  2'b10

`endif // CONTROL_SEL