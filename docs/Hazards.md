# Hazards

## Stalling

There are two times in which we need to stall. All stalls will originate from the ex stage and will work by sending a signal to the ID and IF stages. This signal will disable the pipeline registers and program counter for one cycle.

#### Branch Predictor/Target Generator

```asm
lw   x1, 0(x2)
jalr x0, 0(x1)
```

For this we need to stall for 1 cycle.

| Inst             |     |     |     |     |     |     |     |     |
| ---------------- | --- | --- | --- | --- | --- | --- | --- | --- |
| `lw x1, 0(x2)`   | IF  | ID  | EX  | MEM | WB  |     |     |     |
| `nop`            |     |     |     |     |     |     |     |     |
| `nop`            |     |     |     |     |     |     |     |     |
| `jalr x0, 0(x1)` |     |     |     | IF  | ID  | EX  | MEM | WB  |

To handle memory to branch predictor/target generator hazards, we will need to stall for two cycles. Therefore, it is actually better to skip branch prediction/target generation when this happens as it avoids a stall:

| Inst             |     |     |     |     |     |     |     |
| ---------------- | --- | --- | --- | --- | --- | --- | --- |
| `lw x1, 0(x2)`   | IF  | ID  | EX  | M   | WB  |     |     |
| `nop`            |     |     |     |     |     |     |     |
| `jalr x0, 0(x1)` |     |     | IF  | ID  | EX  | M   | WB  |

To handle this, we should have the control logic disable the branch predictor/target generator. The following stage will then detect the `jalr` instruction, see that to calculate it we need to wait on the `lw` instruction and therefore initiate a stall for one cycle. Note that we should still skip even if this load instruction is one cycle apart.

#### ALU

```asm
lw x1, 0(x3)
addi x1, x1, 100
```

| Inst               |     |     |     |     |     |     |     |
| ------------------ | --- | --- | --- | --- | --- | --- | --- |
| `lw x1, 0(x3)`     | IF  | ID  | EX  | M   | WB  |     |     |
| `nop`              |     |     |     |     |     |     |     |
| `addi x1, x1, 100` |     |     | IF  | ID  | EX  | M   | WB  |

To handle memory to ALU data hazards, we will need to stall for one cycle. Then, we will forward the data from the WB stage to the EX stage. We will do this whenever `rd == rs1` or `rd == rs2` and the instruction in the M stage is a load type instruction.
