# EECS 151/251A FPGA Project Fall 2025
![CPU Diagram](/docs/diagram.svg)

Notes:
- Each color represents a pipeline stage
- Gray is used for components shared by multiple stages
- IF and ID stages have an internal stall/flush signal that connects to all pipeline registers and the program counter (not illustrated).

# Resources:
- [Control Logic Truth Table](https://docs.google.com/spreadsheets/d/1F11mK-QQdbO019NtSGYmiA2lq3mlxW7HmSdNwWFxmQU/edit?usp=sharing)
- [RISC-V ISA Manual](https://riscv.org/wp-content/uploads/2017/05/riscv-spec-v2.2.pdf) (Sections 2.2 - 2.6)
- [Project Spec](https://inst.eecs.berkeley.edu/~eecs151/fa25/static/fpga/project)