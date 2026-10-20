# Zero to hero: a guided path through this repository

For someone who has never written Verilog. Each stage: **learn → read the RTL → run the test → change something → check yourself**. All commands run from the repository root; setup is in the [simulation guide](../simulation/simulation-workflows.md). Time estimates are rough.

| Stage | Topic | You will build/understand | Read | Run | Try |
|---|---|---|---|---|---|
| 0 | Setup | simulator works | [simulation guide](../simulation/simulation-workflows.md) | `python scripts/run_tests.py --check-tools` | run `--list` |
| 1 | Gates and Verilog styles | the same half adder three ways | `rtl/arithmetic/half_adder.v` | `python scripts/run_tests.py --test tb_half_full_adders` | break `carry` (use `\|`), rerun, watch it FAIL, undo |
| 2 | Adders and subtractors | full adder from two half adders; borrow semantics | `full_adder.v`, `full_subtractor.v`, [Task I](../task01-combinational-design.md) | `--test tb_ripple` | trace 13 + 7 by hand, compare with the waveform |
| 3 | Universal gates | everything from NAND or NOR | `nand_nor_arith.v`, [gate counts](../gate-count-analysis/task01_nand_nor_gate_counts.md) | `python tools/verification/gate_count.py` | redraw `half_adder_nand` on paper |
| 4 | Multipliers | partial products, why 2N bits | `mult_unsigned.v` | `--test tb_multipliers` | compute 5 × 6 as shifted adds |
| 5 | Boolean algebra | truth table → SOP/POS → K-map | [Task II](../task02-boolean-minimization.md), [demo_f4 derivation](../boolean-derivations/demo_f4.md) | `python tools/boolean_design/boolean_design.py --config config/boolean_function.example.json` | write your own config with a different minterm list |
| 6 | Multiplexers | `y = d[s]`, building 16:1 from 2:1 | `rtl/mux/*`, [Task III](../task03-mux-decoder-encoder.md) | `--test tb_mux` | implement your config function with `_mux8` and read the data inputs |
| 7 | Decoders, encoders, demux | one-hot, priority, active-low | `rtl/decoder`, `rtl/encoder`, `rtl/demux` | `--test tb_decoder`, `--test tb_encoder_demux` | explain why a simple encoder needs `valid` |
| 8 | Datapath blocks | comparator, incrementer, divider, parity | `rtl/datapath/*` | `--test tb_datapath`, `--test tb_divider_parity` | hand-divide 13 ÷ 4 with the restoring algorithm |
| 9 | ALU and flags | opcode-driven datapath, carry vs overflow | `rtl/alu/*`, [Task IV](../task04-alu-fpga.md) | `--test tb_alu` | find inputs where `carry=1` but `overflow=0` and vice versa |
| 10 | Fast and signed arithmetic | carry-lookahead, Booth | `cla_adder.v`, `booth_mult.v`, [theory](../theory/README.md) | `--test tb_booth`, `--test tb_cla` | follow the [Booth trace](../simulation/booth_trace_N4.txt) by hand |
| 11 | Verification craft | self-checking testbenches, VCD | `tb/task04/tb_alu.v` | `python scripts/make_waveforms.py` | write a testbench for your own module; inject a bug and confirm it fails |
| 12 | FPGA | synthesis → pins → program | [FPGA guide](../fpga/quartus-de10-workflow.md) | (needs Quartus and a board) | fill the pin template from your board manual |

## Self-check questions (answers are in the linked documents)
1. Why does a 4×4 unsigned multiplier need 8 output bits? ([Task I](../task01-combinational-design.md))
2. In a full subtractor, what is the difference between `bin` and `bout`? ([Task I](../task01-combinational-design.md))
3. Why is `A'·B` the half-subtractor borrow and not `A·B'`? (computing A − B)
4. What makes `y = d[s]` hold for the hierarchical 16:1 MUX? ([Task III](../task03-mux-decoder-encoder.md))
5. How does `decoder4to16` use a 1:2 decoder and two 3:8 decoders? ([Task III](../task03-mux-decoder-encoder.md))
6. For `d = 00000110`, what do the simple and priority encoders output, and why? ([Task III](../task03-mux-decoder-encoder.md))
7. Which ALU flags are meaningful for XOR? ([Task IV](../task04-alu-fpga.md))
8. Why does the Booth accumulator have N+1 bits? ([Task IV](../task04-alu-fpga.md))
9. Why is a CLA faster than a ripple adder in principle, and what does it cost? ([theory](../theory/carry-lookahead.md))
10. What does the divider return for a zero divisor? (`rtl/datapath/divider.v` header)

## Capstone ideas
* Add a barrel shifter to the ALU as a new opcode block (needs a wider opcode: update `alu_opcodes.vh`, both ALUs, the testbench and the docs).
* Write a sequential (clocked) divider and compare it with `divider_restoring`.
* Run `fpga_alu4_top` on a board and record your own results in your report.
