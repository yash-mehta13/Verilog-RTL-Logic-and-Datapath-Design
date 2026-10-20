#!/usr/bin/env python3
"""Portable test runner for the Digital Systems Design Lab repository.

Discovers every self-checking testbench, compiles it together with all
synthesizable RTL using Icarus Verilog, runs it with vvp and reports the
result. Uses only the Python standard library.

    python scripts/run_tests.py                 # run everything
    python scripts/run_tests.py --task 3        # one task (1-4) or 'examples'
    python scripts/run_tests.py --test tb_alu   # one testbench by name
    python scripts/run_tests.py --list          # list discovered tests
    python scripts/run_tests.py --check-tools   # report simulator availability
    python scripts/run_tests.py --lint          # compile RTL alone, check names
    python scripts/run_tests.py --vcd           # also write VCD for *_wave tests

Exit codes: 0 all passed, 1 at least one failure, 2 required tool missing
(tests are then reported as BLOCKED, never as passed).
A testbench passes only if it prints a line starting with "RESULT: PASS".
"""
import argparse
import json
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RTL_DIR = ROOT / "rtl"
GEN_DIR = ROOT / "sim" / "generated"
INCLUDE_DIRS = [RTL_DIR / "alu"]
IVERILOG_FLAGS = ["-g2001", "-Wall", "-Wno-timescale"]


def find_tools():
    return {"iverilog": shutil.which("iverilog"), "vvp": shutil.which("vvp"),
            "gtkwave": shutil.which("gtkwave"), "yosys": shutil.which("yosys")}


def rtl_files():
    return sorted(RTL_DIR.rglob("*.v"))


def discover():
    """Return a list of dicts: name, task, tb, extra (extra RTL files)."""
    tests = []
    for tb in sorted((ROOT / "tb").glob("task0*/tb_*.v")):
        tests.append({"name": tb.stem, "task": tb.parent.name[-1], "tb": tb, "extra": []})
    for tb in sorted((ROOT / "examples").glob("*/*/tb_*.v")):
        extra = sorted(p for p in tb.parent.glob("*.v") if not p.name.startswith("tb_"))
        tests.append({"name": tb.stem, "task": "examples", "tb": tb, "extra": extra})
    return tests


def lint(tools):
    """Compile RTL alone with -Wall; flag warnings and duplicate module names."""
    problems = []
    names = {}
    for f in rtl_files():
        for m in re.finditer(r"^\s*module\s+(\w+)", f.read_text(), re.M):
            if m.group(1) in names:
                problems.append(f"duplicate module {m.group(1)} in {f} and {names[m.group(1)]}")
            names[m.group(1)] = f
    cmd = [tools["iverilog"], *IVERILOG_FLAGS, "-o", str(GEN_DIR / "build" / "lint.vvp")]
    for d in INCLUDE_DIRS:
        cmd += ["-I", str(d)]
    cmd += [str(f) for f in rtl_files()]
    (GEN_DIR / "build").mkdir(parents=True, exist_ok=True)
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT)
    out = (r.stdout + r.stderr).strip()
    if r.returncode != 0 or out:
        problems.append("iverilog output:\n" + out)
    print(f"lint: {len(names)} modules in {len(rtl_files())} files")
    for p in problems:
        print("LINT PROBLEM:", p)
    return not problems


def run_one(test, tools, vcd):
    build = GEN_DIR / "build"
    logs = GEN_DIR / "logs"
    build.mkdir(parents=True, exist_ok=True)
    logs.mkdir(parents=True, exist_ok=True)
    vvp_file = build / f"{test['name']}.vvp"
    cmd = [tools["iverilog"], *IVERILOG_FLAGS, "-s", test["name"], "-o", str(vvp_file)]
    for d in INCLUDE_DIRS:
        cmd += ["-I", str(d)]
    files = [str(f) for f in rtl_files()] + [str(f) for f in test["extra"]] + [str(test["tb"])]
    t0 = time.time()
    c = subprocess.run(cmd + files, capture_output=True, text=True, cwd=ROOT)
    log = logs / f"{test['name']}.log"
    if c.returncode != 0:
        log.write_text("COMPILE FAILED\n" + c.stdout + c.stderr)
        return {"status": "FAIL", "detail": "compile error (see log)", "secs": time.time() - t0,
                "log": log}
    run = [tools["vvp"], "-n", str(vvp_file)]
    vcd_path = None
    if vcd:
        vcd_dir = GEN_DIR / "vcd"
        vcd_dir.mkdir(parents=True, exist_ok=True)
        vcd_path = vcd_dir / f"{test['name']}.vcd"
        run.append(f"+vcd={vcd_path}")
    r = subprocess.run(run, capture_output=True, text=True, cwd=ROOT)
    out = c.stderr + r.stdout + r.stderr
    log.write_text(out)
    m = re.search(r"^RESULT: (PASS|FAIL)(.*)$", r.stdout, re.M)
    if r.returncode == 0 and m and m.group(1) == "PASS":
        status, detail = "PASS", m.group(2).strip()
    else:
        status = "FAIL"
        detail = m.group(0) if m else "no RESULT line printed"
    return {"status": status, "detail": detail, "secs": time.time() - t0, "log": log,
            "vcd": vcd_path if vcd_path and vcd_path.exists() else None}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--task", help="1-4 or 'examples'")
    ap.add_argument("--test", help="testbench name (e.g. tb_alu); may be a substring")
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--check-tools", action="store_true")
    ap.add_argument("--lint", action="store_true")
    ap.add_argument("--vcd", action="store_true", help="write VCD for *_wave testbenches")
    ap.add_argument("--report", metavar="FILE", help="also write a Markdown results table (use with a full run)")
    ap.add_argument("--vcd-all", action="store_true", help="write VCD for every selected test (large!)")
    args = ap.parse_args()

    tools = find_tools()
    if args.check_tools:
        for k, v in tools.items():
            print(f"{k:9s}: {v or 'NOT FOUND'}")
        if tools["iverilog"]:
            v = subprocess.run([tools["iverilog"], "-V"], capture_output=True, text=True)
            print((v.stdout or v.stderr).splitlines()[0])
        return 0 if tools["iverilog"] and tools["vvp"] else 2

    tests = discover()
    if args.task:
        key = args.task.lstrip("0")
        tests = [t for t in tests if t["task"] == key or t["task"] == args.task]
    if args.test:
        tests = [t for t in tests if args.test in t["name"]]
    if args.list:
        for t in tests:
            print(f"task {t['task']:8s} {t['name']:28s} {t['tb'].relative_to(ROOT)}")
        return 0
    if not tests and not args.lint:
        print("no tests selected")
        return 1

    if not (tools["iverilog"] and tools["vvp"]):
        print("BLOCKED: iverilog/vvp not found on PATH - no simulation was run.")
        print("Install Icarus Verilog (see README) and re-run. Tests are NOT reported as passed.")
        for t in tests:
            print(f"  BLOCKED  {t['name']}")
        return 2

    if args.lint:
        return 0 if lint(tools) else 1

    results = []
    for t in tests:
        want_vcd = args.vcd_all or (args.vcd and t["name"].endswith("_wave"))
        res = run_one(t, tools, want_vcd)
        results.append((t, res))
        print(f"{res['status']:5s} {t['name']:28s} {res['secs']:6.1f}s  {res['detail']}", flush=True)
        if res["status"] != "PASS":
            print(f"      log: {res['log'].relative_to(ROOT)}")

    passed = sum(1 for _, r in results if r["status"] == "PASS")
    print(f"\n{passed}/{len(results)} testbenches passed")
    summary = [{"test": t["name"], "task": t["task"], "status": r["status"], "detail": r["detail"]}
               for t, r in results]
    GEN_DIR.mkdir(parents=True, exist_ok=True)
    (GEN_DIR / "summary.json").write_text(json.dumps(summary, indent=2))
    if args.report:
        ver = subprocess.run([tools["iverilog"], "-V"], capture_output=True, text=True)
        first = (ver.stdout or ver.stderr).splitlines()[0]
        rows = ["| Task | Testbench | Result | Detail |", "|---|---|---|---|"]
        for t, r in results:
            rows.append(f"| {t['task']} | `{t['name']}` | {r['status']} | {r['detail']} |")
        body = ("# Simulation results\n\n<!-- GENERATED by python scripts/run_tests.py --report - do not edit by hand -->\n\n"
                f"Simulator: {first}; flags: `{' '.join(IVERILOG_FLAGS)}`.\n\n"
                + "\n".join(rows) + f"\n\n{passed}/{len(results)} testbenches passed. "
                "`tests=N` counts individual output comparisons performed by the testbench.\n")
        Path(args.report).write_text(body)
        print("wrote", args.report)
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
