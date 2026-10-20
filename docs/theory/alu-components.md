# ALU functional components

An ALU is the combinational datapath block of a CPU that performs arithmetic and logic on its operands. Components (as implemented here - see [Task IV](../task04-alu-fpga.md)):

1. **Arithmetic unit** - adder (ripple or lookahead) with operand inversion and carry-in for subtraction.
2. **Logic unit** - bitwise AND, OR, XOR, XNOR, NOT, pass-through.
3. **Result multiplexer** - an 8:1 MUX driven by the opcode.
4. **Status/flag logic** - carry, borrow, signed overflow, zero, negative.
5. Optional blocks in larger ALUs: shifter/rotator, comparator, multiplier/divider.

Inputs: operands A, B, opcode (control from the control unit). Outputs: result and flags (consumed by branch/condition logic). See the block diagram in Task IV.
