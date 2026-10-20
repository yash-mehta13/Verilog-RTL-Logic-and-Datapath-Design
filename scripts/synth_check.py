#!/usr/bin/env python3
"""Optional synthesizability check with Yosys (open source; not Quartus).

For every module in rtl/ run: read_verilog; hierarchy -top <m>; proc; check -assert
and fail if any latch cell remains after `proc` (unintended latch) or yosys errors.
This is a lint-level check - it does NOT replace Quartus compilation and says
nothing about timing or resource use.

    python scripts/synth_check.py
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent


def main():
    yosys = shutil.which("yosys")
    if not yosys:
        print("SKIPPED: yosys not found (optional tool) - no synthesis check was run")
        return 2
    files = sorted((ROOT / "rtl").rglob("*.v"))
    mods = []
    for f in files:
        mods += re.findall(r"^\s*module\s+(\w+)", f.read_text(), re.M)
    reads = " ".join(f"-I {ROOT / 'rtl' / 'alu'} {f}" for f in files[:0])
    bad = 0
    for m in mods:
        script = (f"read_verilog -I {ROOT / 'rtl' / 'alu'} " + " ".join(str(f) for f in files) +
                  f"; hierarchy -check -top {m}; proc; check -assert; stat")
        r = subprocess.run([yosys, "-q", "-p", script, "-l", "/dev/stdout"], capture_output=True, text=True)
        out = r.stdout + r.stderr
        latches = re.findall(r"\$_?[A-Za-z]*LATCH[A-Za-z_]*\s+(\d+)", out) or re.findall(r"\$dlatch\s+(\d+)", out)
        if r.returncode != 0 or latches:
            bad += 1
            print(f"FAIL {m}: {'latch inferred' if latches else 'yosys error'}")
            print("\n".join(out.splitlines()[-8:]))
    print(f"yosys check: {len(mods) - bad}/{len(mods)} modules clean (hierarchy -check, proc, check -assert, no latches)")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
