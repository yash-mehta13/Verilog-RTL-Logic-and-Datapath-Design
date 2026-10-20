# Task II - Boolean expressions, minimization and gate realizations

## Aim
Given a truth-table-defined function F (the sheet: "using registration number"), derive canonical and minimal SOP/POS for F and F', realize them as AND-OR-INV, OR-AND-INV, NAND-NAND and NOR-NOR circuits using only two-input gates, count the gates and verify in Verilog.

## Assignment-specific limitation (important)
The sheets say "using registration number" but define **no rule** mapping a registration number to a truth table. This repository therefore does **not** invent one. Instead the function is supplied as an explicit minterm list in a JSON config. Three clearly labelled **demonstration** functions are included (`config/*.json`); they are *not* anyone's assigned function. To use your own: put your minterms (and optional don't-cares) in a copy of `config/boolean_function.example.json` and rerun the generator.

## Requirements covered
Canonical SOP/POS of F and F', K-map + Boolean-law simplification, AOI/OAI/NAND/NOR circuits (2-input gates only), NAND/NOR gate counts and comparison, behavioral/dataflow/structural Verilog, testbench.

## Workflow / commands
```
python tools/boolean_design/boolean_design.py --config config/boolean_function.example.json
python tools/boolean_design/boolean_design.py --config config/boolean_function.example.json --check   # fail if outputs are stale
python scripts/run_tests.py --task examples
```
Config fields: `name`, `variables` (MSB first), `minterms`, `dont_cares`, `outputs {f, fn}`, `description`, `is_demonstration`, `mapping_rule` (leave `null` unless your course documents one). 2-6 variables are supported for analysis/gates/RTL; K-map drawings up to 4; MUX/decoder realizations up to 4.

Outputs per config `<name>`:
| File | Content |
|---|---|
| `docs/boolean-derivations/<name>.md` | truth table, canonical/minimal forms, K-map, merge steps, networks, candidate comparison |
| `docs/truth-tables/<name>_truth_table.md` | truth table |
| `docs/gate-count-analysis/<name>_gate_counts.md` | counts, cross-checked against the generated Verilog |
| `assets/diagrams/kmap_<name>.svg` | K-map figure |
| `examples/registration-function/<name>/` | generated RTL (`_bh _df _aoi _oai _nand _nor _mux16 _mux8 _dec`) + testbench |

## Method
1. Truth table from the config (independent of everything below).
2. Quine-McCluskey prime implicants with exact minimum cover (fewest terms, then literals); don't-cares may be used to enlarge groups but never need to be covered.
3. F' minimized the same way on the zeros; the **POS of F** is derived from the minimal SOP of F' by De Morgan, and vice versa.
4. Boolean-law justification: each prime implicant is listed with the actual sequence of combining-theorem merges `X·Y + X·Y' = X` the tool performed. The tool does **not** produce free-form algebraic proofs; equivalence is established by exhaustive evaluation of every expression against the truth table.
5. Netlists: complemented literals need inverters (inputs are available in true form only); k-input terms are balanced trees of 2-input gates; shared structure is merged; NAND/NOR inverters are tied-input gates and counted.

![K-map of the demonstration function](../assets/diagrams/kmap_demo_f4.svg)

*Figure - K-maps of `demo_f4` (DEMONSTRATION function, not an assigned one), generated; `assets/diagrams/kmap_demo_f4.svg`.*

## Worked demonstration (`demo_f4`, F = Σm(0,1,2,5,6,7,8,9,10,14))
* F (min SOP) = `B'·C' + C·D' + A'·B·D`;  F' (min SOP) = `B'·C·D + B·C'·D' + A·B·D`
* F (min POS) = `(B + C' + D')·(B' + C + D)·(A' + B' + D')`;  F' (min POS) = `(B + C)·(C' + D)·(A + B' + D')`
* Networks emitted for F and F' together (shared input inverters): AOI 20, OAI 20, NAND-NAND 22, NOR-NOR 22 two-input gates.
* Full candidate tables (including unminimized canonical networks: 47 NAND for F vs 12 minimal) in [`docs/boolean-derivations/demo_f4.md`](boolean-derivations/demo_f4.md).

**Polarity conventions.** AOI network: output of the AND-OR is F, the extra INV gives F'; i.e. `F' = INV(SOP of F)` and `F = INV(SOP of F')`. Same for OAI with POS. NAND-NAND realizes F (or F') directly from the SOP; NOR-NOR from the POS. Outputs are active-high in all four.

**"Proof of fewer elements".** The tool compares *the candidate circuits it actually constructs and verifies* (minimal vs canonical; direct vs complement + inverter; NAND vs NOR) and marks the smallest among them. That is a defensible comparison between built circuits; it is **not** a proof of global optimality. For `demo_f4`, the cheapest evaluated way to get F with NAND is the direct minimal SOP (12 gates) while F' is cheaper as "F's network + 1 inverter" (13 vs 15 gates) - results can differ per polarity.

## Testing
`tb_<name>.v` is generated per config: all 2^n minterms; every implementation's F and F' compared with the config table; F and F' complementary at each care input; don't-care rows are skipped. Demonstration functions: `demo_f4` (4 vars), `demo_dc` (don't-cares), `demo_f3` (3 vars). Results: [test_results.md](simulation/test_results.md).

## Inference / Result
All nine realizations of each demonstration function agree with the truth table on every care input. The workflow regenerates all artifacts from the config; nothing in the derivation depends on a registration number.

## Real-world applications
Two-level logic minimization underlies PLA/CPLD mapping, decoder/control logic design, and standard-cell NAND/NOR technology mapping.
