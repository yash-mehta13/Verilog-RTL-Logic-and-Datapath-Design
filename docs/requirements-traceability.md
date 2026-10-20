# Requirements traceability

Summarized from the four course task sheets (BECE102P Digital Systems Design Lab, tasks I-IV). "Status": **Done** = implemented and simulated; **Doc** = documented only; **Open** = needs the student's own input or hardware.

| # | Sheet requirement (summary) | Location | Status |
|---|---|---|---|
| I.1 | 4-bit adder from full adders; FA from half adders + gates; behavioral/structural/dataflow | `ripple_adder4`, `full_adder`, `half_adder`; `tb_ripple_adder`, `tb_half_full_adders` | Done |
| I.2 | 2x2, 3x3, 4x4 multipliers | `rtl/multipliers/mult_unsigned.v`; `tb_multipliers` | Done |
| I.3 | FA / FS using MUX or decoder | `rtl/arithmetic/fa_fs_mux_decoder.v` | Done |
| I.4 | 4-bit adder with basic gates | `ripple_adder4_gates` | Done |
| I.4a/b | Number of 2-input NAND / NOR gates for HA, HS, FA, FS; justify fewer elements | [gate counts](gate-count-analysis/task01_nand_nor_gate_counts.md) | Done (justification limited to the built circuits; no global-minimum claim) |
| I.5 | n-bit parallel adder; "add your internal marks" | `ripple_adder_n`; synthetic example in Task I doc | Done; **Open:** student's real marks are not included |
| I.6-10 | ModelSim waveform, snips, report sections, testbench, applications | testbenches, [simulation guide](simulation/simulation-workflows.md), task docs | Done (Icarus); **Open:** ModelSim snips by the student |
| II | F, F' from registration number: SOP/POS, K-map, laws, AOI/OAI/NAND/NOR, counts | `tools/boolean_design`, [Task II doc](task02-boolean-minimization.md) | Done for configurable/demo functions. **Open / ambiguous:** the sheet gives no registration-number-to-function rule - not invented; student supplies minterms |
| II (counts) | "Proof" that circuit uses fewer gates | candidate comparison in the generated reports | Done as comparison of constructed circuits only |
| III.I.a | 16:1 from 8:1 from 4:1 from 2:1 | `mux16/mux8/mux4/mux2` | Done |
| III.I.b | 2:1 internals SOP/POS/NAND/NOR, CMOS, transmission gate | `mux2_*`; CMOS/TG figure | Done (RTL); CMOS/TG conceptual drawing only |
| III.I.c-d | Registration-number function with 16:1 and 8:1 MUX; MUX versions of Task II CLC | generated `<name>_mux16/_mux8` | Done for demo/config functions; same Open item as Task II |
| III.I.e | Tool steps | [simulation guide](simulation/simulation-workflows.md) | Done (Icarus/ModelSim commands; ModelSim not executed) |
| III.II.a-b | 4:16 ← 3:8 ← 2:4; 2:4 internals SOP/POS/NAND/NOR | `rtl/decoder/*` | Done |
| III.II.c-d | Function with decoder; Verilog + waveforms | `<name>_dec`, decoder wave | Done |
| III.II.f | Priority encoder / encoder, compare enc/dec, priority/simple, demux/mux | `rtl/encoder`, `rtl/demux`, Task III doc | Done |
| IV.1 | ALU 1/4/8-bit with 8 functions | `rtl/alu` | Done |
| IV.2 | Datapath elements (incrementer, decrementer, adder/subtractor, comparator, multiplier, decoder, encoder, ...) | `rtl/datapath`, `rtl/multipliers`, ... | Done incl. divider (`divider_restoring`) and parity generator/checker |
| IV.3 | Half adder on DE10 with Quartus 20.1 Lite | `rtl/fpga`, [FPGA guide](fpga/quartus-de10-workflow.md) | Doc only - Quartus/board unavailable |
| IV.4 | Assigned circuit on DE10 | `fpga_alu4_top` as an example | Doc only; **Open:** the student's assigned circuit is unknown |
| IV.5 | 4-bit comparator (SL) from 1-bit (BL, SL, DFL) | `comparator1*`, `comparator4` | Done |
| IV theory | FPGA vs ASIC, calculator vs computer, Booth multiplier + flowchart + circuit, ALU components + block diagram, RISC vs CISC, CLA | [docs/theory](theory/README.md), Task IV doc | Done |
| IV refs | Use Scopus/IEEE papers | [references](references.md) | **Open:** none verifiable offline; none invented |
| General | Viva: Multisim Live / CircuitVerse implementation | - | Not provided (online tools) |
| General | Visio diagrams, personal front sheets, name/registration data | - | Not provided; no personal data in repo |

## Ambiguities recorded
1. Registration-number rule absent → configurable minterm input (Task II/III).
2. DE10 variant / device / pins absent → templates with placeholders.
3. Sheets reuse example identifiers/slot data from a sample student; ignored (personal data, not requirements).
4. "Subjective to modification" (Version 1) sheets - requirements may change; this table reflects the supplied copies.
