#!/usr/bin/env python3
"""Render selected signals of a real VCD file (from vvp/Icarus) as an SVG.

The picture is drawn directly from the value changes recorded in the VCD; no
value is invented. Standard library only.

    python tools/visualization/vcd_to_svg.py dump.vcd out.svg \
        --title "Module under test" --signal a --signal b --signal sum:h
    signal spec:  <name suffix>[:<radix>]   radix = b (binary) | h (hex) | d (unsigned decimal) | s (signed decimal)
"""
import argparse
import re
import sys
from xml.sax.saxutils import escape


def parse_vcd(path):
    """Return (timescale_str, {id: (fullname, width)}, {id: [(time, value_str)]}, end_time)."""
    timescale, scopes, vars_, changes = "", [], {}, {}
    t, in_defs = 0, True
    with open(path) as fh:
        tokens = fh.read().split()
    i = 0
    while i < len(tokens):
        tok = tokens[i]
        if tok == "$timescale":
            j = tokens.index("$end", i)
            timescale = "".join(tokens[i + 1:j])
            i = j
        elif tok == "$scope":
            scopes.append(tokens[i + 2])
            i = tokens.index("$end", i)
        elif tok == "$upscope":
            scopes.pop()
            i = tokens.index("$end", i)
        elif tok == "$var":
            width, ident, name = int(tokens[i + 2]), tokens[i + 3], tokens[i + 4]
            full = ".".join(scopes + [name])
            vars_.setdefault(ident, [])
            vars_[ident].append((full, width))
            changes.setdefault(ident, [])
            i = tokens.index("$end", i)
        elif tok == "$enddefinitions":
            in_defs = False
            i = tokens.index("$end", i)
        elif tok in ("$dumpvars", "$dumpall", "$dumpon", "$dumpoff", "$end"):
            pass
        elif not in_defs:
            if tok.startswith("#"):
                t = int(tok[1:])
            elif tok[0] in "bB":
                changes[tokens[i + 1]].append((t, tok[1:]))
                i += 1
            elif tok[0] in "01xXzZ":
                changes[tok[1:]].append((t, tok[0]))
        i += 1
    return timescale, vars_, changes, t


def to_int(v, signed, width):
    if re.search(r"[xXzZ]", v):
        return None
    n = int(v, 2)
    if signed and v[0] == "1" and len(v) >= width:
        n -= 1 << width
    return n


def fmt(v, radix, width):
    v = v.rjust(width, v[0] if v[0] in "xXzZ" else "0")
    if re.search(r"[xXzZ]", v):
        return "x"
    n = int(v, 2)
    if radix == "b":
        return v
    if radix == "d":
        return str(n)
    if radix == "s":
        return str(n - (1 << width) if v[0] == "1" else n)
    return format(n, "x").rjust((width + 3) // 4, "0")


def value_at(ch, t):
    cur = None
    for (tt, v) in ch:
        if tt <= t:
            cur = v
        else:
            break
    return cur


def render(vcd, out, title, signals, t_end=None, t_start=0, subtitle=""):
    timescale, vars_, changes, last = parse_vcd(vcd)
    t_end = t_end if t_end is not None else last
    by_name = {}
    for ident, lst in vars_.items():
        for full, width in lst:
            by_name[full] = (ident, width)
    rows = []
    for spec in signals:
        name, _, radix = spec.partition(":")
        radix = radix or "h"
        matches = [f for f in by_name if f == name or f.endswith("." + name)]
        if not matches:
            raise SystemExit(f"signal '{name}' not found in {vcd}; available: {sorted(by_name)[:40]}")
        full = sorted(matches, key=len)[0]
        ident, width = by_name[full]
        rows.append((name.split(".")[-1], full, ident, width, radix))

    left, plot_w, row_h, top = 170, 900, 38, 78
    W, H = left + plot_w + 30, top + row_h * len(rows) + 50
    span = max(t_end - t_start, 1)
    X = lambda t: left + (t - t_start) / span * plot_w
    ts = {"1ps": 1e-3, "1ns": 1.0, "1fs": 1e-6}.get(timescale, 1.0)   # ns per VCD unit
    o = [f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" '
         f'font-family="Helvetica, Arial, sans-serif" role="img">',
         f'<title>{escape(title)}</title>',
         f'<desc>Waveform rendered from the Icarus Verilog VCD file {escape(vcd.split("/")[-1])} '
         f'(VCD timescale {escape(timescale)}). Simulation output, not hardware measurement.</desc>',
         f'<rect width="{W}" height="{H}" fill="#ffffff"/>',
         f'<text x="16" y="26" font-size="17" font-weight="bold" fill="#111">{escape(title)}</text>',
         f'<text x="16" y="46" font-size="12" fill="#444">{escape(subtitle)} Source: {escape(vcd.split("/")[-1])} '
         f'(Icarus Verilog simulation, time in ns).</text>']
    # time grid
    step_ns = 10 ** max(0, len(str(int(span * ts))) - 2)
    for mult in (1, 2, 5, 10):
        if span * ts / (step_ns * mult) <= 14:
            step_ns *= mult
            break
    k = 0
    while True:
        tn = t_start * ts + k * step_ns
        if tn > t_end * ts + 1e-9:
            break
        x = X(tn / ts)
        o.append(f'<line x1="{x:.1f}" y1="{top - 6}" x2="{x:.1f}" y2="{top + row_h * len(rows)}" stroke="#d9d9d9" stroke-width="1"/>')
        o.append(f'<text x="{x:.1f}" y="{top - 12}" font-size="11" text-anchor="middle" fill="#555">{tn:g}</text>')
        k += 1
    o.append(f'<text x="{left + plot_w + 24}" y="{top - 12}" font-size="11" text-anchor="end" fill="#555">ns</text>')
    for r, (label, full, ident, width, radix) in enumerate(rows):
        y0 = top + r * row_h
        ymid = y0 + row_h / 2
        o.append(f'<text x="{left - 10}" y="{ymid + 4}" font-size="13" text-anchor="end" fill="#111">{escape(label)}'
                 f'{"[" + str(width - 1) + ":0]" if width > 1 else ""}</text>')
        ch = changes[ident]
        pts = [(t, v) for t, v in ch if t_start <= t <= t_end]
        init = value_at(ch, t_start)
        segs = []
        times = [t_start] + [t for t, _ in pts if t > t_start] + [t_end]
        times = sorted(set(times))
        for a, b in zip(times, times[1:]):
            segs.append((a, b, value_at(ch, a)))
        hi, lo = y0 + 7, y0 + row_h - 7
        if width == 1:
            prev = None
            path = ""
            for a, b, v in segs:
                if v is None:
                    continue
                yy = hi if v == "1" else lo
                col = "#c0392b" if v in "xXzZ" else "#1f4e79"
                if prev is not None and prev != yy:
                    path += f'<line x1="{X(a):.1f}" y1="{prev}" x2="{X(a):.1f}" y2="{yy}" stroke="#1f4e79" stroke-width="2"/>'
                path += f'<line x1="{X(a):.1f}" y1="{yy}" x2="{X(b):.1f}" y2="{yy}" stroke="{col}" stroke-width="2"/>'
                prev = yy
            o.append(path)
        else:
            for a, b, v in segs:
                if v is None:
                    continue
                x1, x2 = X(a), X(b)
                bad = bool(re.search(r"[xXzZ]", v))
                o.append(f'<polygon points="{x1 + 3:.1f},{ymid:.1f} {x1 + 7:.1f},{hi} {x2 - 7:.1f},{hi} {x2 - 3:.1f},{ymid:.1f} '
                         f'{x2 - 7:.1f},{lo} {x1 + 7:.1f},{lo}" fill="{"#fdecea" if bad else "#eaf2fa"}" '
                         f'stroke="{"#c0392b" if bad else "#1f4e79"}" stroke-width="1.5"/>')
                text = fmt(v, radix, width)
                if (x2 - x1) > 7 * len(text) + 14:
                    o.append(f'<text x="{(x1 + x2) / 2:.1f}" y="{ymid + 4:.1f}" font-size="11" text-anchor="middle" fill="#111">{escape(text)}</text>')
        o.append(f'<line x1="{left}" y1="{y0 + row_h}" x2="{left + plot_w}" y2="{y0 + row_h}" stroke="#eee"/>')
    o.append("</svg>")
    with open(out, "w") as fh:
        fh.write("\n".join(o) + "\n")


if __name__ == "__main__":
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("vcd")
    ap.add_argument("out")
    ap.add_argument("--title", default="Simulation waveform")
    ap.add_argument("--subtitle", default="")
    ap.add_argument("--signal", action="append", required=True)
    ap.add_argument("--t-start", type=int, default=0)
    ap.add_argument("--t-end", type=int)
    a = ap.parse_args()
    render(a.vcd, a.out, a.title, a.signal, a.t_end, a.t_start, a.subtitle)
