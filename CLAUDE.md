# Guidance for Claude sessions

## Verilog
* Verilog-2001 only for `rtl/` and `tb/` (compile with `iverilog -g2001`): ANSI ports, `generate`, `localparam`; no `logic`, `always_comb`, packages, interfaces, `$clog2`.
* Synthesizable RTL has no delays, file I/O or testbench tasks. Simulation-only code lives in `tb/` (and generated `tb_*.v`).
* Naming: plain module name = structural (or the canonical building block), `_df` dataflow, `_bh` behavioral, `_n` active-low wrapper, `_nand`/`_nor`/`_sop`/`_pos` gate realizations. Module names are unique repo-wide (`--lint` checks).
* Opcodes live only in `rtl/alu/alu_opcodes.vh`. Keep widths explicit; give every combinational block default assignments; avoid latches (`scripts/synth_check.py`).
* Selector convention: `y = d[s]`, bit 0 = LSB. State polarity in names (`_n` = active low).

## Testing rules
* Every block needs a self-checking testbench with a reference that is **independent** of the DUT (integer arithmetic, explicit table, config minterms). Never edit expected values to make a failing test pass - fix the RTL.
* Testbenches print `RESULT: PASS tests=N` / `RESULT: FAIL ...` and honour `+vcd=<file>`. The runner decides pass/fail from that line.
* Run `python scripts/run_tests.py` and `python scripts/verify_docs.py` before finishing; run `make check-generated` after touching generators, configs, RTL used in diagrams, or the NAND/NOR file.

## Truth tables and Boolean work
* Truth tables derive from `config/*.json` or Python reference models, never from the RTL under test.
* Do not invent a registration-number-to-minterm rule; do not present demonstration functions as assigned ones.
* Gate counts must come from the netlists actually built; never claim global optimality.

## Results must be genuinely generated
* Never write simulation results, waveforms, gate counts or FPGA outcomes by hand. Generated files (`docs/simulation/test_results.md`, `docs/**/*gate*`, `docs/truth-tables/*`, `docs/boolean-derivations/*`, `assets/diagrams/*.svg`, `assets/waveforms/*`, `examples/registration-function/*`) are regenerated, not edited.
* If a tool (simulator, Quartus, ModelSim, board) is unavailable, say it was not run. No fake screenshots, no invented pin assignments or DE10 device IDs.
* Do not commit course PDFs or personal data (name, registration number). Do not copy third-party code or long passages.
