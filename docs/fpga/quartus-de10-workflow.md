# Quartus Prime Lite 20.1 / DE10 workflow (documented, NOT executed)

**Status:** Quartus Prime and a DE10 board were not available when this repository was built. Nothing here was compiled, programmed or measured; there are no board photos, LED results or resource reports. The steps below are the standard flow for the tools named in the course sheet, to be followed by someone who has them.

**Not provided on purpose:** the exact DE10 variant, FPGA device part number and pin numbers. The sheet does not name them, and guessed pins can damage hardware setups or silently mis-wire a demo. Read them from your board's user manual / schematic.

## Files
| File | Purpose |
|---|---|
| `rtl/fpga/fpga_half_adder_top.v` | half adder: `sw[0]=A`, `sw[1]=B`, `led[0]=SUM`, `led[1]=CARRY` (needs `rtl/arithmetic/half_adder.v`) |
| `rtl/fpga/fpga_alu4_top.v` | 4-bit ALU demo: `sw[2:0]=A`, `sw[5:3]=B`, `sw[8:6]=opcode`, `led[3:0]=result`, `led[8:4]={negative,zero,overflow,borrow,carry}` (needs `rtl/alu/*.v`, add `rtl/alu` to the include path) |
| `fpga/pin_assignments.template.csv` | pin table with `<placeholders>` |
| `fpga/create_project.template.tcl` | project-creation script template with placeholders |

Polarity: tops assume active-high switches/LEDs; many boards use active-low LEDs/buttons - check the schematic and invert in the top if needed.

## Procedure (Quartus Prime Lite 20.1)
1. **New project:** File → New Project Wizard. Working directory outside the repo (or a `quartus/` folder - it is git-ignored), project name e.g. `half_adder_de10`, **top-level entity** `fpga_half_adder_top`.
2. **Add files:** `rtl/arithmetic/half_adder.v` and `rtl/fpga/fpga_half_adder_top.v`.
3. **Device:** choose the device that matches **your** board's manual (family, package, speed grade). Do not guess.
4. **Processing → Start Analysis & Synthesis.** Check there are no errors and review warnings (e.g. unused inputs).
5. **Assignments → Pin Planner** (or edit the `.qsf`): assign `sw[*]`, `led[*]` using the pins and I/O standard from the manual; fill `fpga/pin_assignments.template.csv` as your record. Re-run Analysis & Elaboration if the planner needs it.
6. **Processing → Start Compilation** (fitter + assembler). Confirm a `.sof` is produced.
7. **Tools → Programmer:** Hardware Setup → the board's USB-Blaster (driver installed), Mode JTAG, add the `.sof`, Start.
8. **Hardware check:** toggle the switches through all four combinations and compare with the half-adder truth table: `00→SUM 0, CARRY 0`, `01→1,0`, `10→1,0`, `11→0,1` (A is `sw[0]`, B is `sw[1]`). Record results yourself (photo/table) - none are supplied here.
9. For the assigned circuit / ALU repeat with `fpga_alu4_top`; add `rtl/alu` to Settings → Files / Libraries → include search path for `alu_opcodes.vh`.

![FPGA flow](../../assets/diagrams/fpga_flow.svg)

*Figure - documented flow (`assets/diagrams/fpga_flow.svg`).*

## Version note
Course target: Quartus Prime 20.1 Lite. If you use a newer version the wizard layout and device support differ; follow the course version when possible and note any differences in your report.

## Expected outputs and limitations
Expected: the LED pattern above. Limitations: no timing constraints are needed for this static demo; real switches bounce (irrelevant for combinational demos); the ALU top limits operands to 0-7 so everything fits on 9 switches.
