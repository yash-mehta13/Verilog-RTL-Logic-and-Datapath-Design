# Simulation workflows

## Default: Icarus Verilog + vvp (Linux, macOS, Windows)
Install (not bundled): Debian/Ubuntu `sudo apt-get install iverilog gtkwave`; macOS `brew install icarus-verilog gtkwave`; Windows: the Icarus Verilog installer, or MSYS2/WSL. Then:

```
python scripts/run_tests.py --check-tools     # which tools were found
python scripts/run_tests.py                   # run every testbench
python scripts/run_tests.py --task 4          # one task (1-4 or 'examples')
python scripts/run_tests.py --test tb_alu     # one testbench (substring match)
python scripts/run_tests.py --list
python scripts/run_tests.py --lint            # RTL alone with -Wall + duplicate module check
python scripts/make_waveforms.py              # VCD + SVG waveforms from *_wave testbenches
```
Windows PowerShell uses exactly the same `python scripts\run_tests.py ...` commands (the runner uses `pathlib`, no absolute paths). `make` targets are a Linux/macOS convenience only.

If `iverilog`/`vvp` are missing the runner prints `BLOCKED` and exits with code 2 - it never reports a pass without running the simulator. A testbench passes only when it prints `RESULT: PASS`. Logs go to `sim/generated/logs/`, build products to `sim/generated/build/` (both git-ignored).

### Single module by hand
```
iverilog -g2001 -Wall -I rtl/alu -s tb_decoder -o /tmp/tb.vvp $(find rtl -name '*.v') tb/task03/tb_decoder.v
vvp -n /tmp/tb.vvp +vcd=decoder.vcd
gtkwave decoder.vcd
```
(`+vcd=<file>` is honoured by every testbench; Verilog-2001 has no exit-code API, so the runner decides pass/fail from the `RESULT:` line.)

### Optional synthesizability lint
`python scripts/synth_check.py` runs Yosys `proc; check -assert` on every module and fails on inferred latches. This is a lint, **not** a Quartus compilation.

## ModelSim / Questa (course tool)
```
vlib work
vlog +incdir+rtl/alu rtl/*/*.v tb/task03/tb_decoder.v
vsim -c work.tb_decoder -do "run -all; quit"
```
Look for the `RESULT:` line. For waveforms: `vsim work.tb_decoder`, add the DUT signals, `run -all`. These commands were **not executed** here (ModelSim was unavailable); the sources use only Verilog-2001 constructs. Testbenches use `$value$plusargs`, `$dumpfile` and `$display`, which ModelSim supports.

## Waveforms
Rendered figures in `assets/waveforms/*.svg` come from the real VCDs next to them (`*.vcd`, produced by the `*_wave` testbenches) via `tools/visualization/vcd_to_svg.py`; they are simulation output, not hardware measurements. Open a VCD in GTKWave for interactive viewing. Regenerate with `python scripts/make_waveforms.py`.

## Online simulators (course sheet mentions them)
Online Verilog simulators were **not** used and no links are claimed. If you submit a link, paste your own.
