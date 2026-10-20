# Submission checklist (mapping the sheets' contents index to this repository)

The task sheets ask each student to assemble their own front sheet and report. This repository supplies the technical material; **personal data (name, registration number, slot, photo), screenshots of your own tool runs, and hardware results are yours to add.** Nothing personal is stored here.

Legend: **Repo** = artifact exists here; **You** = you must produce/attach it.

## Task I
| Contents-sheet item | Where | Who |
|---|---|---|
| Aim, components & tools, procedure & theory | [Task I doc](task01-combinational-design.md) | Repo (adapt wording) |
| Pin diagram | module ports in `rtl/arithmetic/*.v`; block figures in the doc | Repo |
| Truth tables and Boolean expressions (HA, FA, HS, FS, 4-bit adder, multiplier) | [truth tables](truth-tables/task01_arithmetic.md) | Repo |
| Circuit diagrams HA, FA, HS, FS | `assets/diagrams/half_adder.svg`, `full_adder_from_half_adders.svg`, `full_subtractor.svg`, `nand_nor_*.svg` | Repo (Visio redraw optional) |
| 4-bit adder / subtractor / adder-subtractor diagrams | `ripple_adder4.svg`; `ripple_subtractor4`, `adder_subtractor` RTL | Repo |
| 4×4 and 3×3 multiplier circuit diagrams | structure described in Task I doc; `mult_array_n` | Repo (text) / You (hand-drawn if required) |
| Verilog: structural, behavioral, dataflow, conditional-operator | `_st`/plain, `_bh`, `_df` modules (conditional operator: `mux2`, `decoder*_df`) | Repo |
| Test bench | `tb/task01/` | Repo |
| Waveform snips with explanation | `assets/waveforms/*.svg` (Icarus); ModelSim snips | Repo (Icarus) / **You** (ModelSim) |
| Online Verilog simulation links | none provided | **You** |
| Result, inference | Task I doc | Repo |
| Internal marks via n-bit adder | `ripple_adder_n`, synthetic example in Task I doc | **You** (your real marks) |
| Multisim Live / CircuitVerse viva circuits | - | **You** |

## Task II
| Item | Where | Who |
|---|---|---|
| Registration-number function | config JSON | **You** (supply your own minterms; no rule is defined by the sheet) |
| Truth table, canonical SOP/POS, laws, K-map, simplified SOP/POS | generated `docs/boolean-derivations/<name>.md` | Repo (rerun with your config) |
| AOI, OAI, NAND, NOR circuit diagrams | gate-level figures: add via the generated netlists (`examples/.../<name>_rtl.v`); K-map figure generated | Repo / You (diagrams for your function) |
| NAND / NOR gate counts and comparison | generated gate-count report | Repo |
| Verilog SL (AOI/OAI/NAND/NOR), BL, DFL, test bench | generated `examples/registration-function/<name>/` | Repo |
| Waveform snips, online links, result, inference | - | **You** (run your function) |

## Task III
| Item | Where | Who |
|---|---|---|
| 16:1←8:1←4:1←2:1; 2:1 internals; CMOS/TG | [Task III doc](task03-mux-decoder-encoder.md) | Repo (CMOS/TG conceptual) |
| Your function with 16:1 and 8:1 MUX; MUX versions of Task II CLC | generated `<name>_mux16`, `<name>_mux8` | Repo (rerun with your config) |
| 4:16←3:8←2:4; 2:4 internals; function with decoder | `rtl/decoder`, `<name>_dec` | Repo |
| Priority encoder / encoder; comparisons | `rtl/encoder`, Task III doc | Repo |
| ModelSim steps and waveforms | [simulation guide](simulation/simulation-workflows.md) | Repo (steps) / **You** (snips) |

## Task IV
| Item | Where | Who |
|---|---|---|
| 1/4/8-bit ALU, function table, block and circuit diagrams | [Task IV doc](task04-alu-fpga.md), `alu_block.svg`, `alu_st` | Repo |
| Datapath elements theory (comparator, adder, multiplier, Booth, MUX, decoder) | Task IV doc, [theory](theory/README.md) | Repo |
| Booth: code, flowchart, circuit | `booth_mult`, `booth_flowchart.svg`, `booth_datapath.svg` | Repo |
| CLA design and working principle | `cla_adder4`, `cla_adder4.svg`, theory | Repo |
| 4-bit comparator from 1-bit | `comparator4` | Repo |
| FPGA: half adder and assigned circuit on DE10 | [FPGA guide](fpga/quartus-de10-workflow.md) | **You** (board, pins, photos) |
| FPGA vs ASIC, calculator vs computer, RISC vs CISC | [theory](theory/README.md) | Repo |
| Merits/demerits, applications, IEEE/Scopus references | applications in each doc; [references](references.md) | **You** (papers you have actually read) |
