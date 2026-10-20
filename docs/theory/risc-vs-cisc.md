# RISC vs CISC

| | RISC | CISC |
|---|---|---|
| Instruction set | Small, simple, mostly uniform-length | Large, many complex and variable-length instructions |
| Memory access | Load/store only; operations work on registers | Many instructions operate directly on memory operands |
| Control | Simple decode; often hardwired | Richer decode; microcode is common |
| Registers | Usually many general-purpose registers | Often fewer |
| Pipelining | Easier (regular instructions) | Harder, decode more complex |
| Code size | Larger for the same task (more instructions) | Smaller |
| Examples | MIPS, ARM, RISC-V | x86 |

Modern CISC processors (x86) internally translate instructions into simpler micro-operations, so the practical boundary is blurred.
