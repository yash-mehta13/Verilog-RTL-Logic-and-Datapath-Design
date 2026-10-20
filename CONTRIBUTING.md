# Contributing

## Add a circuit
1. Put the module in the matching `rtl/<family>/` file (or a new file); follow the naming convention in [CLAUDE.md](CLAUDE.md). Keep it Verilog-2001 and synthesizable.
2. Write `tb/taskNN/tb_<name>.v`: enumerate (or sample with a fixed seed) inputs, compute the expected result independently, print `FAIL ...` lines, and finish with `RESULT: PASS tests=N` or `RESULT: FAIL errors=E tests=N`; accept `+vcd=<file>` as in the existing testbenches.
3. `python scripts/run_tests.py --test tb_<name>` then the full suite. `python scripts/run_tests.py --lint` and `python scripts/synth_check.py` must stay clean.

## Boolean functions
Copy `config/boolean_function.example.json`, set `variables` (MSB first) and `minterms` (and `dont_cares`), set `is_demonstration` to `false` only for a function that really is yours, then run `python tools/boolean_design/boolean_design.py --config <file>`. Commit the regenerated files; `--check` verifies freshness.

## Diagrams and waveforms
Edit `scripts/render_diagrams.py` (editable source), run `python scripts/render_diagrams.py`. Waveforms: add a `*_wave` testbench and an entry in `scripts/make_waveforms.py`, then `python scripts/make_waveforms.py`.

## Truth tables and gate counts
`python tools/verification/gen_truth_tables.py --write`, `python tools/verification/gate_count.py --write`. Keep one primitive per line in `rtl/arithmetic/nand_nor_arith.v` (the counter parses it).

## Before a pull request
`make all-checks` (or the python commands in `Makefile`), update [CHANGELOG.md](CHANGELOG.md) with what you really changed, do not add course PDFs, personal data or unverified claims.
