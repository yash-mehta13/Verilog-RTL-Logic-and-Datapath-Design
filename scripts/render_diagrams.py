#!/usr/bin/env python3
"""Generate the project's SVG diagrams (editable source = this script).

    python scripts/render_diagrams.py            # write assets/diagrams/*.svg
    python scripts/render_diagrams.py --check    # fail if any SVG is stale

Gate-level figures (NAND/NOR adders, 2:1 MUX internals, half adder) are drawn
automatically from the primitive instances parsed out of the RTL source, so
they always match the code. Block diagrams and flowcharts are laid out by
hand below; their signal names follow the RTL port names.
The K-map figures are produced by tools/boolean_design/boolean_design.py.
"""
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools" / "visualization"))
sys.path.insert(0, str(ROOT / "tools" / "verification"))
from svgkit import ACCENT, BLUE, INK, Canvas, draw_netlist  # noqa: E402
from gate_count import parse_netlist  # noqa: E402

OUT = ROOT / "assets" / "diagrams"
DIAGRAMS = {}


def diagram(fn):
    DIAGRAMS[fn.__name__] = fn
    return fn


def arrow(cv, x1, y1, x2, y2, label=None, dy=-6):
    cv.line(x1, y1, x2, y2, arrow=True)
    if label:
        cv.text((x1 + x2) / 2, (y1 + y2) / 2 + dy, label, size=11, anchor="middle", color="#444")


# ----------------------------------------------------------------- 1
@diagram
def repo_overview():
    cv = Canvas(1100, 520, "Repository overview and RTL verification workflow",
                "Four lab tasks feed one shared RTL library; every module is checked by self-checking testbenches run by scripts/run_tests.py.")
    cv.text(30, 34, "Digital Systems Design Lab - repository overview", size=20, weight="bold")
    tasks = [("Task I", "adders, subtractors,", "multipliers, NAND/NOR"),
             ("Task II", "Boolean F / F',", "SOP/POS, K-map, gates"),
             ("Task III", "MUX, DEMUX,", "decoders, encoders"),
             ("Task IV", "ALU 1/4/8-bit, CLA,", "Booth, comparator, FPGA")]
    for i, t in enumerate(tasks):
        cv.box(30 + i * 260, 60, 230, 74, t, fill=["blue", "green", "orange", "purple"][i])
        arrow(cv, 145 + i * 260, 134, 145 + i * 260, 170)
    cv.box(30, 170, 1010, 64, ["rtl/  - synthesizable Verilog-2001 library (one authoritative copy)",
                              "arithmetic | multipliers | mux | decoder | encoder | demux | datapath | alu | fpga"],
           fill="grey", size=13)
    cv.box(30, 270, 230, 70, ["config/*.json", "truth-table spec"], fill="green")
    cv.box(290, 270, 230, 70, ["tools/boolean_design", "QM, K-map, nets, RTL+TB"], fill="green")
    arrow(cv, 260, 305, 290, 305)
    cv.box(550, 270, 230, 70, ["tb/task01..04", "self-checking testbenches"], fill="blue")
    cv.box(810, 270, 230, 70, ["examples/registration-function", "generated RTL + testbenches"], fill="green")
    arrow(cv, 520, 320, 810, 320, "generates")
    arrow(cv, 665, 234, 665, 270)
    cv.box(290, 390, 230, 70, ["scripts/run_tests.py", "iverilog -g2001 + vvp"], fill="yellow")
    arrow(cv, 665, 340, 470, 390)
    arrow(cv, 925, 340, 520, 410)
    cv.box(550, 390, 230, 70, ["RESULT: PASS / FAIL", "logs + summary.json"], fill="white")
    arrow(cv, 520, 425, 550, 425)
    cv.box(810, 390, 230, 70, ["VCD -> waveform SVG", "assets/waveforms"], fill="white")
    arrow(cv, 780, 425, 810, 425, "*_wave tests")
    cv.box(30, 390, 230, 70, ["docs/ + assets/diagrams", "reports, figures"], fill="purple")
    arrow(cv, 290, 425, 260, 425)
    cv.text(30, 500, "CI (.github/workflows/rtl-ci.yml) runs the same commands. Quartus/DE10 steps are documented only; they need no CI.",
            size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 2
@diagram
def half_adder():
    text = (ROOT / "rtl/arithmetic/half_adder.v").read_text()
    gates, al = parse_netlist(text, "half_adder")
    cv = Canvas(760, 260, "Half adder: truth table and gate circuit",
                "SUM = A xor B, CARRY = A and B; circuit drawn from module half_adder (rtl/arithmetic/half_adder.v).")
    cv.text(20, 30, "Half adder  (module half_adder)", size=18, weight="bold")
    cv.table(30, 60, ["a", "b", "sum", "carry"], [["0", "0", "0", "0"], ["0", "1", "1", "0"],
                                                 ["1", "0", "1", "0"], ["1", "1", "0", "1"]],
             colw=48, highlight_cols=(2, 3))
    draw_netlist(cv, gates, ["a", "b"], ["sum", "carry"], 300, 40)
    cv.text(30, 200, "sum = a ⊕ b", size=14, family="Menlo, Consolas, monospace")
    cv.text(30, 224, "carry = a · b", size=14, family="Menlo, Consolas, monospace")
    return cv


def two_cell_chain(title, desc, cell, ins3, outs, first_outs, second_outs, or_out, file_note):
    cv = Canvas(900, 320, title, desc)
    cv.text(20, 30, title, size=18, weight="bold")
    a, b, c = ins3
    cv.box(140, 70, 150, 90, [cell, f"{cell[0:4]}0"], fill="blue")
    cv.box(390, 120, 150, 90, [cell, f"{cell[0:4]}1"], fill="blue")
    for i, n in enumerate((a, b)):
        y = 95 + i * 40
        cv.text(70, y + 4, n, size=14, weight="bold", anchor="end")
        arrow(cv, 76, y, 140, y)
    cv.text(70, 194, c, size=14, weight="bold", anchor="end")
    cv.poly([(76, 190), (390, 190)], arrow=True)
    arrow(cv, 290, 100, 390, 145, first_outs[0])
    cv.poly([(290, 135), (330, 135), (330, 250), (600, 250)], arrow=False)
    cv.text(300, 128, first_outs[1], size=11, color="#444")
    ins, out = cv.gate("or", 600, 215)
    cv.line(560, 228, ins[0][0], ins[0][1])
    cv.poly([(540, 185), (560, 185), (560, 226), (ins[0][0], 226)])
    cv.poly([(600 - 0, 250), (ins[1][0], ins[1][1] + 2)])
    cv.text(560, 178, second_outs[1], size=11, color="#444")
    arrow(cv, out[0], out[1], out[0] + 70, out[1])
    cv.text(out[0] + 76, out[1] + 5, or_out, size=14, weight="bold", color=ACCENT["orange"])
    arrow(cv, 540, 145, 760, 145)
    cv.text(766, 150, outs[0], size=14, weight="bold", color=ACCENT["orange"])
    for i, ln in enumerate(file_note.split("|")):
        cv.text(20, 276 + i * 18, ln.strip(), size=12, color="#555")
    return cv


@diagram
def full_adder_from_half_adders():
    cv = two_cell_chain("Full adder = two half adders + OR",
                        "Structural full adder (module full_adder): ha0 adds a and b, ha1 adds the partial sum and cin, OR combines the carries.",
                        "half_adder", ("a", "b", "cin"), ("sum", "cout"), ("s1", "c1"), ("sum", "c2"), "cout",
                        "sum = a ⊕ b ⊕ cin  |  cout = a·b + cin·(a ⊕ b)  |  source: rtl/arithmetic/full_adder.v")
    return cv


@diagram
def full_subtractor():
    cv = two_cell_chain("Full subtractor = two half subtractors + OR",
                        "Structural full subtractor (module full_subtractor): hs0 computes a-b, hs1 subtracts bin, OR combines the borrows.",
                        "half_subtractor", ("a", "b", "bin"), ("diff", "bout"), ("d1", "b1"), ("diff", "b2"), "bout",
                        "diff = a ⊕ b ⊕ bin  |  bout = a'·b + (a ⊕ b)'·bin  |  source: rtl/arithmetic/full_subtractor.v")
    return cv


# ----------------------------------------------------------------- 5
@diagram
def ripple_adder4():
    cv = Canvas(980, 300, "4-bit ripple-carry adder",
                "Four full_adder stages; carry c[i+1] of stage i feeds stage i+1 (module ripple_adder4).")
    cv.text(20, 30, "4-bit ripple-carry adder  (module ripple_adder4)", size=18, weight="bold")
    xs = [760, 540, 320, 100]
    for i, x in enumerate(xs):
        cv.box(x, 110, 140, 80, ["full_adder", f"stage[{i}]"], fill="blue")
        cv.text(x + 40, 70, f"a[{i}]", size=13, anchor="middle", weight="bold")
        cv.text(x + 100, 70, f"b[{i}]", size=13, anchor="middle", weight="bold")
        arrow(cv, x + 40, 76, x + 40, 110)
        arrow(cv, x + 100, 76, x + 100, 110)
        arrow(cv, x + 70, 190, x + 70, 240)
        cv.text(x + 70, 258, f"sum[{i}]", size=13, anchor="middle", weight="bold", color=ACCENT["orange"])
    cv.text(960, 154, "cin = c[0]", size=13, anchor="end", weight="bold")
    arrow(cv, 900 + 60, 160, 900, 160)
    for i in range(3):
        x_from = xs[i]
        x_to = xs[i + 1] + 140
        arrow(cv, x_from, 150, x_to, 150, f"c[{i + 1}]")
    arrow(cv, 100, 150, 40, 150)
    cv.text(30, 140, "cout", size=13, weight="bold", color=ACCENT["orange"])
    cv.text(30, 160, "= c[4]", size=12)
    cv.text(20, 288, "Worst-case delay grows linearly with width: the carry may travel through every stage (e.g. 1111 + 0000 + cin=1).",
            size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 6
@diagram
def cla_adder4():
    cv = Canvas(1000, 430, "4-bit carry-lookahead adder",
                "cla_adder4: generate/propagate per bit, a lookahead unit computing every carry from g, p and cin, and sum XORs.")
    cv.text(20, 30, "4-bit carry-lookahead adder  (module cla_adder4)", size=18, weight="bold")
    cv.box(40, 60, 260, 90, ["P/G generation (per bit)", "g[i] = a[i] · b[i]", "p[i] = a[i] ⊕ b[i]"], fill="blue")
    cv.box(370, 60, 300, 90, ["Carry-lookahead unit", "c1..c3, cout from g, p, cin", "(two gate levels after p/g)"], fill="orange")
    cv.box(740, 60, 220, 90, ["Sum XORs", "sum[i] = p[i] ⊕ c[i]"], fill="green")
    cv.text(170, 175, "a[3:0], b[3:0]", size=13, anchor="middle", weight="bold")
    arrow(cv, 170, 165, 170, 150)
    arrow(cv, 300, 105, 370, 105, "g, p")
    arrow(cv, 670, 105, 740, 105, "c[3:0]")
    cv.poly([(250, 150), (250, 200), (850, 200), (850, 150)], arrow=True)
    cv.text(550, 215, "p[3:0]", size=11, anchor="middle", color="#444")
    cv.text(520, 45, "cin", size=13, anchor="middle", weight="bold")
    arrow(cv, 520, 48, 520, 60)
    arrow(cv, 960, 105, 990, 105)
    cv.text(985, 95, "sum", size=12, anchor="end", weight="bold", color=ACCENT["orange"])
    arrow(cv, 520, 150, 520, 185)
    cv.text(530, 182, "cout, group_p, group_g", size=12, color=ACCENT["orange"], weight="bold")
    eq = ["c1 = g0 + p0·c0",
          "c2 = g1 + p1·g0 + p1·p0·c0",
          "c3 = g2 + p2·g1 + p2·p1·g0 + p2·p1·p0·c0",
          "c4 = g3 + p3·g2 + p3·p2·g1 + p3·p2·p1·g0 + p3·p2·p1·p0·c0   (= cout)",
          "group_g = g3 + p3·g2 + p3·p2·g1 + p3·p2·p1·g0      group_p = p3·p2·p1·p0",
          "c0 = cin;  every carry is a two-level AND-OR of g, p, cin - no carry waits for the previous carry"]
    for i, e in enumerate(eq):
        cv.text(40, 260 + i * 26, e, size=14, family="Menlo, Consolas, monospace")
    return cv


# ----------------------------------------------------------------- 7
def netlist_figure(title, desc, panels, w=1100, panel_h=330):
    cv = Canvas(w, 50 + panel_h * len(panels), title, desc)
    cv.text(20, 30, title, size=18, weight="bold")
    text = (ROOT / "rtl/arithmetic/nand_nor_arith.v").read_text()
    for k, (mod, ins, outs, src_text) in enumerate(panels):
        gates, al = parse_netlist(src_text or text, mod)
        n = len(gates)
        kind = gates[0][0].upper()
        draw_netlist(cv, gates, ins, outs, 20, 50 + k * panel_h,
                     title=f"{mod}  -  {n} two-input {kind} gates (tied inputs = inverter)", aliases=al)
    return cv


@diagram
def nand_nor_adders():
    return netlist_figure(
        "Full adder from two-input NAND only and NOR only",
        "Drawn from modules full_adder_nand and full_adder_nor in rtl/arithmetic/nand_nor_arith.v; labels n1.. are the net names in the RTL.",
        [("full_adder_nand", ["a", "b", "cin"], ["sum", "cout"], None),
         ("full_adder_nor", ["a", "b", "cin"], ["sum", "cout"], None)])


@diagram
def nand_nor_half_cells():
    return netlist_figure(
        "Half adder and half subtractor from two-input NAND / NOR",
        "Drawn from half_adder_nand, half_adder_nor, half_subtractor_nand, half_subtractor_nor (rtl/arithmetic/nand_nor_arith.v).",
        [("half_adder_nand", ["a", "b"], ["sum", "carry"], None),
         ("half_adder_nor", ["a", "b"], ["sum", "carry"], None),
         ("half_subtractor_nand", ["a", "b"], ["diff", "borrow"], None),
         ("half_subtractor_nor", ["a", "b"], ["diff", "borrow"], None)], panel_h=250)


@diagram
def nand_nor_subtractors():
    return netlist_figure(
        "Full subtractor from two-input NAND only and NOR only",
        "Drawn from full_subtractor_nand and full_subtractor_nor (rtl/arithmetic/nand_nor_arith.v).",
        [("full_subtractor_nand", ["a", "b", "bin"], ["diff", "bout"], None),
         ("full_subtractor_nor", ["a", "b", "bin"], ["diff", "bout"], None)], w=1250)


@diagram
def mux2_internal():
    text = (ROOT / "rtl/mux/mux2.v").read_text()
    cv = Canvas(1100, 760, "2:1 multiplexer internal realizations",
                "SOP, POS, NAND-only and NOR-only 2:1 MUX drawn from rtl/mux/mux2.v, plus a conceptual transmission-gate MUX.")
    cv.text(20, 30, "2:1 MUX  y = s ? d1 : d0  - gate-level realizations (from rtl/mux/mux2.v)", size=18, weight="bold")
    for k, mod in enumerate(("mux2_sop", "mux2_pos", "mux2_nand", "mux2_nor")):
        gates, al = parse_netlist(text, mod)
        x = 20 + (k % 2) * 540
        y = 60 + (k // 2) * 240
        draw_netlist(cv, gates, ["s", "d0", "d1"], ["y"], x, y, title=f"{mod} ({len(gates)} gates)", aliases=al)
    # transmission-gate MUX (conceptual)
    y0 = 560
    cv.text(20, y0, "Transmission-gate 2:1 MUX (conceptual, transistor level - not modelled in RTL)", size=14, weight="bold")
    for i, (d, ctl, ctln) in enumerate((("d0", "s'", "s"), ("d1", "s", "s'"))):
        yy = y0 + 50 + i * 80
        cv.text(60, yy + 5, d, size=13, weight="bold", anchor="end")
        cv.line(66, yy, 180, yy)
        cv.raw(f'<polygon points="180,{yy - 18} 230,{yy} 180,{yy + 18}" fill="#fff" stroke="{INK}" stroke-width="1.6"/>')
        cv.raw(f'<polygon points="250,{yy - 18} 200,{yy} 250,{yy + 18}" fill="#fff" stroke="{INK}" stroke-width="1.6"/>')
        cv.raw(f'<circle cx="215" cy="{yy - 22}" r="4" fill="#fff" stroke="{INK}"/>')
        cv.line(215, yy - 26, 215, yy - 34)
        cv.text(222, yy - 30, f"{ctln}  (PMOS gate)", size=11)
        cv.line(215, yy + 14, 215, yy + 30)
        cv.text(222, yy + 32, f"{ctl}  (NMOS gate)", size=11)
        cv.line(250, yy, 330, yy)
    cv.line(330, y0 + 50, 330, y0 + 130)
    cv.line(330, y0 + 90, 380, y0 + 90, arrow=True)
    cv.text(386, y0 + 95, "y", size=13, weight="bold", color=ACCENT["orange"])
    cv.text(470, y0 + 60, "s = 0: the d0 gate conducts (NMOS gate = s' = 1), d1 gate is off.", size=12)
    cv.text(470, y0 + 82, "s = 1: the d1 gate conducts, d0 gate is off.", size=12)
    cv.text(470, y0 + 104, "Static CMOS alternative: AOI22 + inverter (y = ((s'·d0) + (s·d1))'').", size=12)
    cv.text(470, y0 + 126, "Illustrative only: no transistor sizing, delay or power data.", size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 8
@diagram
def mux_hierarchy():
    cv = Canvas(1100, 700, "Hierarchical 16:1 multiplexer",
                "mux16 = two mux8 + mux2; mux8 = two mux4 + mux2; mux4 = three mux2. s[0] drives the leaf stage, so y = d[s].")
    cv.text(20, 30, "16:1 MUX built as 8:1 <- 4:1 <- 2:1   (modules mux16, mux8, mux4, mux2)", size=18, weight="bold")
    col_x = [120, 380, 620, 840]
    levels = [8, 4, 2, 1]
    ys = {}
    for L, cnt in enumerate(levels):
        gap = 560 / cnt
        for k in range(cnt):
            y = 60 + gap * k + gap / 2 - 22
            ys[(L, k)] = y
            cv.box(col_x[L], y, 80, 44, ["mux2", f"s[{L}]"], fill=["blue", "green", "orange", "purple"][L], size=11)
            if L == 0:
                for j in range(2):
                    idx = 2 * k + j
                    yy = y + 12 + j * 20
                    cv.text(col_x[0] - 46, yy + 4, f"d[{idx}]", size=11, anchor="end")
                    arrow(cv, col_x[0] - 42, yy, col_x[0], yy)
            else:
                for j in range(2):
                    src = ys[(L - 1, 2 * k + j)]
                    cv.poly([(col_x[L - 1] + 80, src + 22), (col_x[L] - 20, src + 22),
                             (col_x[L] - 20, y + 12 + j * 20), (col_x[L], y + 12 + j * 20)], arrow=True)
    arrow(cv, col_x[3] + 80, ys[(3, 0)] + 22, col_x[3] + 140, ys[(3, 0)] + 22)
    cv.text(col_x[3] + 146, ys[(3, 0)] + 27, "y = d[s]", size=14, weight="bold", color=ACCENT["orange"])
    # group outlines
    for k in range(4):
        y1 = ys[(0, 2 * k)] - 6
        y2 = ys[(0, 2 * k + 1)] + 50
        cv.raw(f'<rect x="{col_x[0] - 8}" y="{y1}" width="{col_x[1] + 96 - col_x[0]}" height="{y2 - y1}" rx="10" '
               f'fill="none" stroke="{ACCENT["green"]}" stroke-dasharray="6 4"/>')
        cv.text(col_x[1] + 84, y1 + 14, "mux4", size=11, anchor="end", color=ACCENT["green"])
    for k in range(2):
        y1 = ys[(0, 4 * k)] - 20
        y2 = ys[(0, 4 * k + 3)] + 56
        cv.raw(f'<rect x="{col_x[0] - 20}" y="{y1}" width="{col_x[2] + 108 - col_x[0]}" height="{y2 - y1}" rx="12" '
               f'fill="none" stroke="{ACCENT["orange"]}" stroke-dasharray="3 3"/>')
        cv.text(col_x[2] + 84, y1 + 14, "mux8", size=11, anchor="end", color=ACCENT["orange"])
    cv.text(20, 690, "15 two-input MUXes in total. Select bits: s[0] -> first column ... s[3] -> last. "
            "Direct alternative: mux16_df (assign y = d[s]).", size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 9
@diagram
def decoder_hierarchy():
    cv = Canvas(1100, 520, "Hierarchical decoders",
                "decoder2to4 = 1:2 steering + two 1:2; decoder3to8 = 1:2 steering + two 2:4; decoder4to16 = 1:2 steering + two 3:8. Active-high enable and outputs.")
    cv.text(20, 30, "Decoder hierarchy: 4:16 <- 3:8 <- 2:4 <- 1:2   (active-high en and y)", size=18, weight="bold")
    cv.box(40, 220, 140, 80, ["decoder1to2", "steering on a[3]"], fill="purple")
    cv.text(110, 330, "en", size=13, anchor="middle", weight="bold")
    arrow(cv, 110, 320, 110, 300)
    cv.text(30, 250, "a[3]", size=12, anchor="end", weight="bold")
    arrow(cv, 34, 246, 40, 246)
    for i, y in enumerate((80, 340)):
        cv.box(300, y, 170, 100, ["decoder3to8", f"en = e[{i}]", "y[" + ("7:0" if i == 0 else "15:8") + "]"], fill="orange")
        cv.poly([(180, 250 + i * 20), (240, 250 + i * 20), (240, y + 50), (300, y + 50)], arrow=True)
        cv.text(250, y + 44, f"e[{i}]", size=11, color="#444")
        arrow(cv, 470, y + 50, 520, y + 50)
        cv.text(526, y + 55, "y[7:0]" if i == 0 else "y[15:8]", size=13, weight="bold", color=ACCENT["orange"])
    cv.text(300, 210, "a[2:0] to both 3:8 blocks", size=12, color="#444")
    # inside a 3:8
    cv.raw(f'<rect x="640" y="60" width="440" height="420" rx="12" fill="none" stroke="{ACCENT["orange"]}" stroke-dasharray="6 4"/>')
    cv.text(660, 84, "inside decoder3to8", size=14, weight="bold", color=ACCENT["orange"])
    cv.box(660, 230, 110, 70, ["decoder1to2", "on a[2]"], fill="purple", size=11)
    for i, y in enumerate((110, 330)):
        cv.box(830, y, 110, 80, ["decoder2to4", f"en=e[{i}]"], fill="green", size=11)
        cv.poly([(770, 255 + i * 20), (800, 255 + i * 20), (800, y + 40), (830, y + 40)], arrow=True)
        arrow(cv, 940, y + 40, 970, y + 40)
        cv.text(975, y + 45, "y[3:0]" if i == 0 else "y[7:4]", size=12, weight="bold")
    cv.text(830, 222, "each 2:4 = 1:2 on a[1]", size=11, color="#444")
    cv.text(830, 238, "+ two 1:2 on a[0]", size=11, color="#444")
    cv.text(20, 505, "Active-low wrappers (decoder2to4_n, decoder3to8_n, decoder4to16_n): en_n = 0 enables; the selected y_n output is 0.",
            size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 10
@diagram
def encoder_vs_priority():
    cv = Canvas(1100, 430, "Simple encoder vs priority encoder",
                "encoder8to3 asserts valid only for one-hot inputs; priority_encoder8to3 outputs the highest asserted index.")
    cv.text(20, 30, "8:3 encoder vs 8:3 priority encoder", size=18, weight="bold")
    cv.box(40, 60, 480, 80, ["encoder8to3 (simple)", "assumes exactly one input is 1",
                             "valid = 1 only for one-hot d; otherwise y is meaningless"], fill="blue", size=12)
    cv.box(580, 60, 480, 80, ["priority_encoder8to3", "highest set bit wins",
                              "valid = |d ; d = 0 gives y = 0, valid = 0"], fill="orange", size=12)
    rows_s = [["00000001", "000", "1"], ["00001000", "011", "1"], ["00000110", "(011)", "0"],
              ["00000000", "(000)", "0"]]
    rows_p = [["00000001", "000", "1"], ["00001000", "011", "1"], ["00000110", "010", "1"],
              ["00000000", "000", "0"]]
    cv.table(90, 170, ["d[7:0]", "y", "valid"], rows_s, colw=120, rowh=30, size=13, highlight_cols=(1, 2))
    cv.table(630, 170, ["d[7:0]", "y", "valid"], rows_p, colw=120, rowh=30, size=13, highlight_cols=(1, 2))
    cv.text(90, 350, "(..) = raw OR-gate output, not a valid code: the simple encoder does not prioritize.", size=12, color="#555")
    cv.text(630, 350, "d = 00000110: inputs 1 and 2 both active -> index 2 reported.", size=12, color="#555")
    cv.text(40, 400, "Equations (priority): y2 = d7+d6+d5+d4;  y1 = d7+d6+d5'd4'(d3+d2);  y0 = d7+d6'd5+d6'd4'd3+d6'd4'd2'd1",
            size=13, family="Menlo, Consolas, monospace")
    return cv


# ----------------------------------------------------------------- 11
@diagram
def alu_block():
    cv = Canvas(1100, 520, "ALU block diagram",
                "Parameterized ALU: arithmetic unit (add/sub), logic unit, 8:1 result MUX selected by op, and flag logic.")
    cv.text(20, 30, "ALU  (alu #(WIDTH) / alu_st; wrappers alu_1bit, alu_4bit, alu_8bit)", size=18, weight="bold")
    cv.text(60, 90, "a[W-1:0]", size=14, weight="bold")
    cv.text(60, 200, "b[W-1:0]", size=14, weight="bold")
    cv.box(220, 60, 240, 90, ["Arithmetic unit", "a + b      (op 000)", "a + ~b + 1 (op 001)"], fill="blue", size=12)
    cv.box(220, 180, 240, 130, ["Logic unit", "a & b,  a | b,  a ^ b,", "~(a ^ b),  ~a,  b"], fill="green", size=12)
    for y in (85, 205):
        arrow(cv, 140, y, 220, y)
    cv.poly([(140, 205), (180, 205), (180, 120), (220, 120)], arrow=True)
    cv.poly([(140, 85), (170, 85), (170, 250), (220, 250)], arrow=True)
    cv.box(560, 90, 120, 220, ["8:1", "result", "MUX"], fill="orange")
    arrow(cv, 460, 105, 560, 120, "sum")
    arrow(cv, 460, 245, 560, 245, "6 results")
    cv.text(620, 350, "op[2:0]", size=14, weight="bold", anchor="middle")
    arrow(cv, 620, 336, 620, 310)
    arrow(cv, 680, 200, 780, 200)
    cv.text(790, 205, "y[W-1:0]", size=14, weight="bold", color=ACCENT["orange"])
    cv.box(780, 260, 280, 130, ["Flag logic", "carry  (ADD only)", "borrow (SUB only)", "overflow (ADD/SUB, signed)",
                                "zero = (y == 0), negative = y[W-1]"], fill="purple", size=11)
    cv.poly([(460, 135), (500, 135), (500, 400), (920, 400), (920, 390)], arrow=True)
    cv.text(505, 395, "cout, carry into MSB", size=11, color="#444")
    cv.poly([(740, 200), (740, 320), (780, 320)], arrow=True)
    cv.table(40, 360, ["op", "operation"], [["000", "ADD"], ["001", "SUB"], ["010", "AND"], ["011", "OR"]], colw=70, rowh=22)
    cv.table(200, 360, ["op", "operation"], [["100", "XOR"], ["101", "XNOR"], ["110", "NOT A"], ["111", "PASS B"]], colw=70, rowh=22)
    cv.text(20, 505, "carry/borrow/overflow are forced to 0 for logic opcodes; flags are recomputed every evaluation (nothing is held over).",
            size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 12
@diagram
def booth_flowchart():
    cv = Canvas(760, 860, "Booth multiplication flowchart", "Radix-2 Booth algorithm as implemented in booth_mult.")
    cv.text(20, 30, "Booth multiplier - algorithm (module booth_mult)", size=18, weight="bold")
    cx = 300
    cv.box(cx - 90, 50, 180, 44, ["START", "start=1 while idle"], fill="grey", size=12)
    arrow(cv, cx, 94, cx, 120)
    cv.box(cx - 170, 120, 340, 76, ["Initialise", "A = 0 (N+1 bits), Q = multiplier, Q-1 = 0",
                                    "M = sign-extended multiplicand, count = N"], fill="blue", size=12)
    arrow(cv, cx, 196, cx, 230)
    cv.diamond(cx, 280, 220, 100, ["Q[0], Q-1 ?"])
    cv.box(560, 200, 160, 50, ["A = A + M"], fill="green")
    cv.box(560, 310, 160, 50, ["A = A - M"], fill="orange")
    cv.poly([(cx + 110, 280), (500, 280), (500, 225), (560, 225)], arrow=True)
    cv.text(470, 215, "01", size=13, weight="bold")
    cv.poly([(500, 280), (500, 335), (560, 335)], arrow=True)
    cv.text(470, 330, "10", size=13, weight="bold")
    arrow(cv, cx, 330, cx, 410)
    cv.text(cx + 8, 380, "00 or 11 (no add)", size=12)
    cv.poly([(640, 250), (640, 270), (740, 270), (740, 395), (cx + 20, 395), (cx + 20, 410)], arrow=True)
    cv.poly([(640, 360), (640, 380), (740, 380)])
    cv.box(cx - 170, 410, 340, 70, ["Arithmetic shift right", "{A, Q, Q-1} >>> 1  (A's sign bit copied)"], fill="purple", size=12)
    arrow(cv, cx, 480, cx, 510)
    cv.box(cx - 90, 510, 180, 44, ["count = count - 1"], fill="blue", size=12)
    arrow(cv, cx, 554, cx, 590)
    cv.diamond(cx, 640, 200, 100, ["count = 0 ?"])
    cv.poly([(cx - 100, 640), (60, 640), (60, 280), (cx - 110, 280)], arrow=True)
    cv.text(70, 630, "no", size=13, weight="bold")
    arrow(cv, cx, 690, cx, 730)
    cv.text(cx + 8, 715, "yes", size=13, weight="bold")
    cv.box(cx - 170, 730, 340, 76, ["DONE (1-cycle pulse)", "product = {A[N-1:0], Q}  (2N-bit signed)",
                                    "busy = 0, product held until next result"], fill="grey", size=12)
    cv.text(20, 845, "One loop iteration = one clock cycle in the RTL (add/sub and shift happen in the same cycle).",
            size=12, color="#555")
    return cv


@diagram
def booth_datapath():
    cv = Canvas(1000, 520, "Booth multiplier datapath", "Registers, adder/subtractor, shifter and control of booth_mult.")
    cv.text(20, 30, "Booth multiplier datapath (module booth_mult, parameter N)", size=18, weight="bold")
    cv.box(40, 70, 200, 60, ["M register", "{mcand[N-1], mcand}  N+1 bits"], fill="blue", size=11)
    cv.box(330, 180, 230, 80, ["Adder / subtractor", "A+M, A-M or A", "(selected by Q[0], Q-1)"], fill="orange", size=12)
    cv.box(330, 330, 160, 60, ["A register", "N+1 bits"], fill="green", size=12)
    cv.box(510, 330, 160, 60, ["Q register", "N bits (multiplier)"], fill="green", size=12)
    cv.box(690, 330, 80, 60, ["Q-1", "1 bit"], fill="green", size=12)
    cv.box(640, 180, 180, 80, ["Arithmetic", "shift right by 1"], fill="purple", size=12)
    cv.box(840, 70, 140, 110, ["Control", "count (8 bits)", "busy, done", "start, rst_n"], fill="grey", size=11)
    cv.poly([(240, 100), (445, 100), (445, 180)], arrow=True)
    cv.poly([(410, 330), (410, 260)], arrow=True)
    cv.text(380, 300, "A", size=12)
    arrow(cv, 560, 220, 640, 220, "a_op")
    cv.poly([(730, 260), (730, 300), (410, 300), (410, 330)], arrow=False)
    cv.poly([(730, 300), (590, 300), (590, 330)], arrow=True)
    cv.poly([(730, 300), (730, 330)], arrow=True)
    cv.poly([(600, 390), (600, 420), (300, 420), (300, 240), (330, 240)], arrow=True)
    cv.text(310, 415, "Q[0]", size=11)
    cv.poly([(730, 390), (730, 440), (280, 440), (280, 250), (330, 250)], arrow=True)
    cv.text(700, 455, "Q-1", size=11)
    cv.box(790, 330, 190, 60, ["product register (2N bits)", "loaded with {A[N-1:0], Q}", "on the last step"], fill="orange", size=11)
    arrow(cv, 770, 360, 790, 360)
    cv.text(20, 160, "multiplicand, multiplier: sampled when start=1 and busy=0", size=12, color="#555")
    cv.text(20, 500, "Control: count starts at N, one step per clock; done pulses for one cycle when count reaches 0.", size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 14
@diagram
def verification_flow():
    cv = Canvas(1100, 300, "Verification flow", "RTL plus testbench compiled by iverilog, run by vvp, checked against an independent reference model.")
    cv.text(20, 30, "Verification flow (python scripts/run_tests.py)", size=18, weight="bold")
    steps = [("RTL", "rtl/**/*.v", "blue"), ("Testbench", "tb/task0X/tb_*.v", "blue"),
             ("iverilog", "-g2001 -Wall", "yellow"), ("vvp", "simulation", "yellow"),
             ("Self-check", "DUT vs reference", "green"), ("RESULT", "PASS / FAIL", "orange")]
    for i, (a, b, f) in enumerate(steps):
        x = 20 + i * 180
        cv.box(x, 80, 150, 70, [a, b], fill=f, size=12)
        if i:
            arrow(cv, x - 30, 115, x, 115)
    cv.box(560, 200, 260, 60, ["VCD (+vcd=file, *_wave tests)", "-> vcd_to_svg.py -> SVG / GTKWave"], fill="purple", size=12)
    arrow(cv, 650, 150, 650, 200)
    cv.box(20, 200, 480, 60, ["Reference model is independent of the DUT:",
                              "integer arithmetic, explicit tables, or config minterms"], fill="white", size=12, bold_first=False)
    cv.text(20, 290, "A test only passes if the simulator ran and printed 'RESULT: PASS'; a missing simulator is reported as BLOCKED.",
            size=12, color="#555")
    return cv


# ----------------------------------------------------------------- 15
@diagram
def fpga_flow():
    cv = Canvas(1100, 330, "FPGA implementation workflow", "Quartus Prime Lite 20.1 flow for the DE10 board; documented, not executed in this repository.")
    cv.text(20, 30, "FPGA flow - Intel Quartus Prime Lite 20.1, DE10 board (documented procedure, not executed here)", size=17, weight="bold")
    steps = [("1. New project", "top = fpga_half_adder_top"), ("2. Add RTL", "fpga_tops.v + deps"),
             ("3. Device", "from board manual"), ("4. Analysis &", "Synthesis"),
             ("5. Pin assignment", "Pin Planner / QSF"), ("6. Compile", "Fitter + Assembler"),
             ("7. Program", "USB-Blaster, .sof"), ("8. Verify on board", "switches -> LEDs")]
    for i, (a, b) in enumerate(steps):
        x = 20 + (i % 4) * 270
        y = 70 + (i // 4) * 120
        cv.box(x, y, 230, 70, [a, b], fill=["blue", "blue", "orange", "yellow", "orange", "yellow", "green", "green"][i], size=12)
        if i % 4:
            arrow(cv, x - 40, y + 35, x, y + 35)
    cv.poly([(1060 - 20, 140), (1060 - 20, 160), (135, 160), (135, 190)], arrow=True)
    cv.text(20, 300, "Orange steps need board-specific data (device part number, pin numbers) taken from the board's own manual; "
            "they are left as placeholders on purpose.", size=12, color="#555")
    return cv


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    args = ap.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    stale = []
    for name, fn in DIAGRAMS.items():
        svg = fn().svg()
        path = OUT / f"{name}.svg"
        if args.check:
            if not path.exists() or path.read_text() != svg:
                stale.append(path)
        else:
            path.write_text(svg)
            print("wrote", path.relative_to(ROOT))
    if stale:
        for p in stale:
            print("STALE:", p.relative_to(ROOT), file=sys.stderr)
        return 1
    if args.check:
        print(f"{len(DIAGRAMS)} diagrams up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main())
