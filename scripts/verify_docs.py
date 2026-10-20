#!/usr/bin/env python3
"""Documentation / asset consistency checks (standard library only).

* every relative Markdown link and image target exists
* every SVG parses as XML
* backticked repo paths (rtl/..., docs/..., scripts/...) exist
* `python scripts/x.py` / `python tools/...` commands refer to existing files
* `make <target>` mentions refer to Makefile targets
* `--test <name>` mentions match a discovered testbench
* no TODO / TBD / FIXME / placeholder markers in docs or sources

    python scripts/verify_docs.py
"""
import re
import sys
import xml.dom.minidom
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
errors = []


def err(msg):
    errors.append(msg)


def md_files():
    skip = {"sim", ".git", "reference"}
    return [p for p in ROOT.rglob("*.md") if not (set(p.relative_to(ROOT).parts) & skip)]


def check_links(md):
    text = md.read_text()
    text_nocode = re.sub(r"```.*?```", "", text, flags=re.S)
    for m in re.finditer(r"!?\[[^\]]*\]\(([^)\s]+)\)", text_nocode):
        target = m.group(1)
        if re.match(r"[a-z]+:", target) or target.startswith("#"):
            continue
        path = target.split("#")[0]
        if path and not (md.parent / path).resolve().exists():
            err(f"{md.relative_to(ROOT)}: broken link/image -> {target}")


PATH_RE = re.compile(r"`((?:rtl|tb|docs|assets|config|tools|scripts|fpga|examples|\.github)/[^`\s]*)`")


def check_paths(md):
    for m in PATH_RE.finditer(md.read_text()):
        p = m.group(1).rstrip(".,;:")
        if any(c in p for c in "*<>{}") or p.endswith("/..."):
            continue
        if not (ROOT / p).exists():
            err(f"{md.relative_to(ROOT)}: referenced path does not exist -> {p}")


def check_commands(md, make_targets, tests):
    text = md.read_text()
    for m in re.finditer(r"python3?\s+((?:scripts|tools)/[\w/\.]+\.py)", text):
        if not (ROOT / m.group(1)).exists():
            err(f"{md.relative_to(ROOT)}: command references missing script {m.group(1)}")
    for m in re.finditer(r"^\s*make\s+([\w-]+)", text, re.M):
        if m.group(1) not in make_targets:
            err(f"{md.relative_to(ROOT)}: 'make {m.group(1)}' is not a Makefile target")
    for m in re.finditer(r"--test\s+([\w]+)", text):
        if not any(m.group(1) in t for t in tests):
            err(f"{md.relative_to(ROOT)}: --test {m.group(1)} matches no testbench")


def main():
    make_targets = set(re.findall(r"^([\w-]+):", (ROOT / "Makefile").read_text(), re.M))
    tests = [p.stem for p in list((ROOT / "tb").glob("task0*/tb_*.v")) + list((ROOT / "examples").glob("*/*/tb_*.v"))]
    mds = md_files()
    for md in mds:
        check_links(md)
        check_paths(md)
        check_commands(md, make_targets, tests)
    svgs = list((ROOT / "assets").rglob("*.svg"))
    for svg in svgs:
        try:
            xml.dom.minidom.parse(str(svg))
        except Exception as e:  # noqa: BLE001
            err(f"{svg.relative_to(ROOT)}: invalid XML: {e}")
    marker = re.compile(r"\b(TODO|TBD|FIXME|XXX|lorem ipsum)\b", re.I)
    for p in mds + list((ROOT / "rtl").rglob("*.v")) + list((ROOT / "tb").rglob("*.v")) + \
            list((ROOT / "scripts").glob("*.py")) + list((ROOT / "tools").rglob("*.py")):
        if p.name == "verify_docs.py":
            continue
        for i, line in enumerate(p.read_text().splitlines(), 1):
            if marker.search(line):
                err(f"{p.relative_to(ROOT)}:{i}: placeholder marker: {line.strip()[:70]}")
    if errors:
        print("\n".join(errors))
        print(f"\nverify_docs: {len(errors)} problem(s)")
        return 1
    print(f"verify_docs: OK ({len(mds)} markdown files, {len(svgs)} SVG files)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
