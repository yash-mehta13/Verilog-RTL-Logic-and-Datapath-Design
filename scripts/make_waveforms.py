#!/usr/bin/env python3
"""Run the *_wave testbenches with VCD dumping and render waveform SVGs.

Everything is derived from real simulator output:
  1. python scripts/run_tests.py --vcd   (Icarus Verilog + vvp)
  2. tools/visualization/vcd_to_svg.py   (parses the VCD, draws the traces)
The VCD files are copied next to the SVGs (assets/waveforms/) so the pictures
can be reproduced or opened in GTKWave. The Booth trace text is extracted
from the same simulation log.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools" / "visualization"))
from vcd_to_svg import render  # noqa: E402

OUT = ROOT / "assets" / "waveforms"
VCD = ROOT / "sim" / "generated" / "vcd"

FIGURES = [
    ("tb_full_adder_wave", "Full adder (two half adders + OR) and NAND-only full adder",
     "Stimulus: all 8 combinations of a, b, cin, 10 ns each.",
     ["a", "b", "cin", "sum", "cout", "sum_nand", "cout_nand"]),
    ("tb_ripple_adder4_wave", "4-bit ripple-carry adder",
     "Stimulus: 6 directed vectors, 20 ns each (incl. 13+7=20 and 15+0+1).",
     ["a:d", "b:d", "cin", "sum:d", "cout"]),
    ("tb_decoder_wave", "4:16 decoder built from two 3:8 decoders",
     "Stimulus: address 0..15 with en=1, then en=0 for two addresses.",
     ["en", "a:d", "y:b"]),
    ("tb_priority_encoder_wave", "8:3 priority encoder vs simple 8:3 encoder",
     "Stimulus: single, multiple and no asserted inputs, 10 ns each.",
     ["d:b", "y_pri:d", "v_pri", "y_simple:d", "v_simple"]),
    ("tb_alu_wave", "8-bit ALU: opcodes and flags",
     "Stimulus: 8 opcodes on a=5A,b=3C, then flag corner cases, 10 ns each.",
     ["op:d", "a:h", "b:h", "y:h", "carry", "borrow", "overflow", "zero", "negative"]),
    ("tb_booth_wave", "4-bit signed Booth multiplier: (-3)x5 and 7x(-8)",
     "Stimulus: start pulses, 10 ns clock; product shown as signed decimal.",
     ["clk", "start", "busy", "done", "multiplicand:s", "multiplier:s", "product:s"]),
]


def main():
    r = subprocess.run([sys.executable, str(ROOT / "scripts" / "run_tests.py"), "--test", "_wave", "--vcd"],
                       cwd=ROOT)
    if r.returncode != 0:
        print("waveform testbenches did not all pass - not rendering", file=sys.stderr)
        return r.returncode
    OUT.mkdir(parents=True, exist_ok=True)
    for tb, title, sub, sigs in FIGURES:
        src = VCD / f"{tb}.vcd"
        shutil.copy(src, OUT / src.name)
        render(str(OUT / src.name), str(OUT / f"{tb[3:]}.svg"), title, sigs, subtitle=sub)
        print("rendered", (OUT / f"{tb[3:]}.svg").relative_to(ROOT))
    log = (ROOT / "sim" / "generated" / "logs" / "tb_booth_wave.log").read_text()
    trace = [l[6:] for l in log.splitlines() if l.startswith("TRACE ")]
    (ROOT / "docs" / "simulation").mkdir(parents=True, exist_ok=True)
    (ROOT / "docs" / "simulation" / "booth_trace_N4.txt").write_text(
        "# Output of tb/task04/tb_booth_wave.v (Icarus Verilog), N=4.\n"
        "# A is 5 bits (N+1), Q is 4 bits; state shown BEFORE each add/sub + shift step.\n"
        + "\n".join(trace) + "\n")
    print("wrote docs/simulation/booth_trace_N4.txt")
    return 0


if __name__ == "__main__":
    sys.exit(main())
