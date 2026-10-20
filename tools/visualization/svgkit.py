"""Tiny SVG drawing helper used by scripts/render_diagrams.py (stdlib only).

All diagrams use a white background so they stay legible in GitHub light and
dark themes, and an accessible palette (dark blue strokes, pale fills,
Okabe-Ito accent colours).
"""
from xml.sax.saxutils import escape

INK = "#1b2a3a"
BLUE = "#1f4e79"
FILL = {"blue": "#eaf2fa", "orange": "#fff1e0", "green": "#e7f5ec", "grey": "#f2f2f2",
        "purple": "#f3ebf7", "yellow": "#fffbe0", "white": "#ffffff"}
ACCENT = {"blue": "#0072b2", "orange": "#d55e00", "green": "#009e73", "purple": "#cc79a7",
          "yellow": "#e69f00", "grey": "#666666"}


class Canvas:
    def __init__(self, w, h, title, desc=""):
        self.w, self.h = w, h
        self.title, self.desc = title, desc
        self.items = []

    # ---- primitives
    def raw(self, s):
        self.items.append(s)

    def text(self, x, y, s, size=13, anchor="start", weight="normal", color=INK, family=None, italic=False):
        fam = f' font-family="{family}"' if family else ""
        st = ' font-style="italic"' if italic else ""
        self.items.append(f'<text x="{x:.1f}" y="{y:.1f}" font-size="{size}" text-anchor="{anchor}" '
                          f'font-weight="{weight}" fill="{color}"{fam}{st}>{escape(str(s))}</text>')

    def line(self, x1, y1, x2, y2, color=INK, width=1.6, dash=None, arrow=False):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        m = ' marker-end="url(#arrow)"' if arrow else ""
        self.items.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{color}" '
                          f'stroke-width="{width}"{d}{m}/>')

    def poly(self, pts, color=INK, width=1.6, arrow=False, dash=None):
        p = " ".join(f"{x:.1f},{y:.1f}" for x, y in pts)
        m = ' marker-end="url(#arrow)"' if arrow else ""
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.items.append(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{width}"{m}{d}/>')

    def curve(self, x1, y1, x2, y2, color=INK, width=1.4):
        xm = (x1 + x2) / 2
        self.items.append(f'<path d="M{x1:.1f},{y1:.1f} C{xm:.1f},{y1:.1f} {xm:.1f},{y2:.1f} {x2:.1f},{y2:.1f}" '
                          f'fill="none" stroke="{color}" stroke-width="{width}"/>')

    def dot(self, x, y, r=3, color=INK):
        self.items.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="{r}" fill="{color}"/>')

    def box(self, x, y, w, h, lines=(), fill="blue", stroke=BLUE, size=13, rx=8, bold_first=True, dash=None):
        d = f' stroke-dasharray="{dash}"' if dash else ""
        self.items.append(f'<rect x="{x:.1f}" y="{y:.1f}" width="{w:.1f}" height="{h:.1f}" rx="{rx}" '
                          f'fill="{FILL.get(fill, fill)}" stroke="{stroke}" stroke-width="1.6"{d}/>')
        lines = [lines] if isinstance(lines, str) else list(lines)
        n = len(lines)
        for i, s in enumerate(lines):
            yy = y + h / 2 + (i - (n - 1) / 2) * (size + 4) + size * 0.35
            self.text(x + w / 2, yy, s, size=size if i or not bold_first else size + 1, anchor="middle",
                      weight="bold" if (i == 0 and bold_first) else "normal")
        return (x, y, w, h)

    def diamond(self, cx, cy, w, h, lines, fill="yellow"):
        pts = f"{cx},{cy - h / 2} {cx + w / 2},{cy} {cx},{cy + h / 2} {cx - w / 2},{cy}"
        self.items.append(f'<polygon points="{pts}" fill="{FILL[fill]}" stroke="{BLUE}" stroke-width="1.6"/>')
        lines = [lines] if isinstance(lines, str) else lines
        for i, s in enumerate(lines):
            self.text(cx, cy + (i - (len(lines) - 1) / 2) * 16 + 4, s, size=12, anchor="middle")

    def table(self, x, y, header, rows, colw=36, rowh=20, size=12, highlight_cols=()):
        cols = len(header)
        for j, h in enumerate(header):
            fill = "#dbe7f3" if j not in highlight_cols else "#fde3c9"
            self.items.append(f'<rect x="{x + j * colw}" y="{y}" width="{colw}" height="{rowh}" fill="{fill}" stroke="#7a8a99"/>')
            self.text(x + j * colw + colw / 2, y + rowh * 0.7, h, size=size, anchor="middle", weight="bold")
        for i, r in enumerate(rows):
            for j, v in enumerate(r):
                fill = "#ffffff" if j not in highlight_cols else "#fff6ec"
                self.items.append(f'<rect x="{x + j * colw}" y="{y + (i + 1) * rowh}" width="{colw}" height="{rowh}" fill="{fill}" stroke="#b5c0cb"/>')
                self.text(x + j * colw + colw / 2, y + (i + 1) * rowh + rowh * 0.7, v, size=size, anchor="middle",
                          family="Menlo, Consolas, monospace")
        return cols * colw, (len(rows) + 1) * rowh

    # ---- logic gates: (x, y) = top-left of a 50x40 body; returns pin coordinates
    def gate(self, kind, x, y, label=None, fill="#ffffff"):
        k = kind.lower()
        s = f'fill="{fill}" stroke="{INK}" stroke-width="1.8"'
        base = k[1:] if k in ("nand", "nor", "xnor") else k
        if k == "nand":
            base = "and"
        if k == "nor":
            base = "or"
        if k == "xnor":
            base = "xor"
        if base == "and":
            self.raw(f'<path d="M{x},{y} H{x + 25} A20,20 0 0 1 {x + 25},{y + 40} H{x} Z" {s}/>')
            ins = [(x, y + 11), (x, y + 29)]
            out = (x + 45, y + 20)
        elif base in ("or", "xor"):
            self.raw(f'<path d="M{x},{y} Q{x + 14},{y + 20} {x},{y + 40} Q{x + 34},{y + 40} {x + 48},{y + 20} '
                     f'Q{x + 34},{y} {x},{y} Z" {s}/>')
            if base == "xor":
                self.raw(f'<path d="M{x - 7},{y} Q{x + 7},{y + 20} {x - 7},{y + 40}" fill="none" stroke="{INK}" stroke-width="1.8"/>')
            ins = [(x + 5 - (7 if base == "xor" else 0), y + 11), (x + 5 - (7 if base == "xor" else 0), y + 29)]
            out = (x + 48, y + 20)
        elif base in ("not", "buf"):
            self.raw(f'<path d="M{x},{y + 4} L{x + 34},{y + 20} L{x},{y + 36} Z" {s}/>')
            ins = [(x, y + 20)]
            out = (x + 34, y + 20)
        else:
            raise ValueError(kind)
        if k in ("nand", "nor", "not", "xnor"):
            self.raw(f'<circle cx="{out[0] + 4}" cy="{out[1]}" r="4" fill="#fff" stroke="{INK}" stroke-width="1.6"/>')
            out = (out[0] + 8, out[1])
        if label:
            self.text(x + 20, y - 4, label, size=10, anchor="middle", color="#555")
        return ins, out

    def svg(self):
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {self.w} {self.h}" width="{self.w}" '
                f'height="{self.h}" font-family="Helvetica, Arial, sans-serif" role="img">\n'
                f'<title>{escape(self.title)}</title>\n<desc>{escape(self.desc or self.title)}</desc>\n'
                '<defs><marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" '
                f'orient="auto-start-reverse"><path d="M0,0 L10,5 L0,10 z" fill="{INK}"/></marker></defs>\n'
                f'<rect width="{self.w}" height="{self.h}" fill="#ffffff"/>\n')
        return head + "\n".join(self.items) + "\n</svg>\n"


def draw_netlist(cv, gates, inputs, outputs, x0, y0, title=None, col_w=118, row_h=64, aliases=None):
    """Levelized drawing of a primitive-gate netlist parsed from Verilog.

    gates: [(op, out, [ins])], inputs: [names], outputs: [names].
    Returns the bounding box height used.
    """
    aliases = aliases or {}
    level = {i: 0 for i in inputs}
    for op, out, ins in gates:
        level[out] = 1 + max(level[i] for i in ins)
    maxl = max(level[o] for _, o, _ in gates)
    pos = {}
    in_gap = row_h * 0.9
    for k, name in enumerate(inputs):
        pos[name] = (x0 + 30, y0 + 40 + k * in_gap)
    cols = {}
    for op, out, ins in gates:
        cols.setdefault(level[out], []).append((op, out, ins))
    pin = {}
    max_y = y0 + 40 + len(inputs) * in_gap
    for L in range(1, maxl + 1):
        col = cols.get(L, [])
        col.sort(key=lambda g: sum(pos[i][1] for i in g[2]) / len(g[2]))
        used = []
        for op, out, ins in col:
            want = sum(pos[i][1] for i in ins) / len(ins) - 20
            yy = want
            for u in sorted(used):
                if abs(yy - u) < row_h:
                    yy = u + row_h
            yy = max(yy, y0 + 20)
            used.append(yy)
            x = x0 + 60 + L * col_w - col_w + 40
            pin[out] = (op, x, yy, ins)
            pos[out] = (x + 58, yy + 20)
            max_y = max(max_y, yy + 60)
    if title:
        cv.text(x0, y0 + 4, title, size=14, weight="bold")
    for name in inputs:
        x, y = pos[name]
        cv.text(x - 8, y + 4, name, size=13, anchor="end", weight="bold")
        cv.dot(x, y)
    for out, (op, x, yy, ins) in pin.items():
        label = None
        ip, op_xy = cv.gate("nand" if op == "nand" else op, x, yy)
        pos[out] = op_xy
    # wires drawn after gates so they stay visible
    for out, (op, x, yy, ins) in pin.items():
        tmp = Canvas(1, 1, "")
        ip, _ = tmp.gate(op, x, yy)
        if len(ins) == 2 and ins[0] == ins[1]:
            src = pos[ins[0]]
            cv.curve(src[0], src[1], ip[0][0] - 8, (ip[0][1] + ip[1][1]) / 2)
            cv.line(ip[0][0] - 8, ip[0][1], ip[0][0] - 8, ip[1][1])
            for p in ip:
                cv.line(ip[0][0] - 8, p[1], p[0], p[1])
        else:
            for (px, py), src_name in zip(ip, ins):
                src = pos[src_name]
                cv.curve(src[0], src[1], px, py)
    # gate labels
    for out, (op, x, yy, ins) in pin.items():
        cv.text(x + 22, yy - 4, out, size=10, anchor="middle", color="#555")
    for o in outputs:
        src = aliases.get(o, o)
        x, y = pos[src]
        cv.line(x, y, x + 26, y, arrow=True)
        cv.text(x + 30, y + 4, o, size=13, weight="bold", color=ACCENT["orange"])
    return max_y - y0
