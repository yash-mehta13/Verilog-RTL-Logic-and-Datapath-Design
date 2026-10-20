#!/usr/bin/env python3
"""Boolean function design toolchain (Task II / Task III item I.c, II.c).

Reads a truth-table configuration (JSON) and generates, reproducibly:

  * truth table, canonical SOP/POS for F and F' (minterm / maxterm lists)
  * minimal SOP and POS via Quine-McCluskey (exact cover, don't-cares aware)
  * K-map text/SVG (up to 4 variables) and the combining-theorem steps
  * gate-level networks with 2-input gates only:
        AND-OR-INV, OR-AND-INV, NAND-NAND, NOR-NOR
    with gate counts for the networks actually emitted, plus comparison
    against other candidate networks
  * Verilog: behavioral, dataflow, structural (AOI/OAI/NAND/NOR),
    16:1 MUX, 8:1 MUX and decoder realizations + a self-checking testbench

Everything is verified in Python against the truth table before files are
written. Nothing here derives a truth table from a registration number: the
mapping from a registration number to minterms is NOT defined by the course
material, so the config file must list the minterms explicitly.

    python tools/boolean_design/boolean_design.py --config config/boolean_function.example.json
    python tools/boolean_design/boolean_design.py --config <file> --check   # fail if outputs stale
"""
import argparse
import itertools
import json
import re
import shutil
import sys
import tempfile
from collections import Counter
from pathlib import Path
from xml.sax.saxutils import escape

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "verification"))
from gate_count import count_primitives  # noqa: E402

MAX_VARS = 6
MAX_HW_VARS = 4   # MUX / decoder realizations use the 16:1 MUX and 4:16 decoder


# ----------------------------------------------------------------- config
def load_config(path):
    cfg = json.loads(Path(path).read_text())
    for key in ("name", "variables", "minterms"):
        if key not in cfg:
            raise SystemExit(f"config error: missing '{key}'")
    n = len(cfg["variables"])
    if not 2 <= n <= MAX_VARS:
        raise SystemExit(f"config error: supports 2..{MAX_VARS} variables, got {n}")
    for v in cfg["variables"]:
        if not re.fullmatch(r"[A-Za-z_]\w*", v):
            raise SystemExit(f"config error: '{v}' is not a valid Verilog identifier")
    if len(set(cfg["variables"])) != n:
        raise SystemExit("config error: duplicate variable names")
    if not re.fullmatch(r"[A-Za-z_]\w*", cfg["name"]):
        raise SystemExit("config error: 'name' must be a Verilog identifier")
    cfg.setdefault("dont_cares", [])
    outs = cfg.setdefault("outputs", {"f": "F", "fn": "F_n"})
    if outs["f"] in cfg["variables"] or outs["fn"] in cfg["variables"] or outs["f"] == outs["fn"]:
        raise SystemExit("config error: output names clash with variables or each other")
    ones, dcs = list(cfg["minterms"]), list(cfg["dont_cares"])
    for m in ones + dcs:
        if not (isinstance(m, int) and 0 <= m < 2 ** n):
            raise SystemExit(f"config error: minterm {m} out of range 0..{2 ** n - 1}")
    if len(set(ones)) != len(ones) or len(set(dcs)) != len(dcs) or set(ones) & set(dcs):
        raise SystemExit("config error: duplicate minterms or minterm/don't-care overlap")
    zeros = [m for m in range(2 ** n) if m not in ones and m not in dcs]
    if not ones or not zeros:
        raise SystemExit("config error: F must have at least one 1 and one 0 (constant functions are not supported)")
    cfg["n"] = n
    cfg["ones"] = sorted(ones)
    cfg["dcs"] = sorted(dcs)
    cfg["zeros"] = zeros
    return cfg


# -------------------------------------------------- Quine-McCluskey (QM)
def covers(cube, m):
    value, mask = cube
    return (m & ~mask) == value


def prime_implicants(terms):
    """Return (primes, parents). parents[cube] = (cubeA, cubeB, eliminated_bit)."""
    cur = {(t, 0) for t in terms}
    primes, parents = set(), {}
    while cur:
        nxt, used = set(), set()
        for a, b in itertools.combinations(sorted(cur), 2):
            if a[1] != b[1]:
                continue
            diff = a[0] ^ b[0]
            if diff and diff & (diff - 1) == 0:
                new = (a[0] & ~diff, a[1] | diff)
                nxt.add(new)
                used.update((a, b))
                parents.setdefault(new, (a, b, diff))
        primes |= cur - used
        cur = nxt
    return primes, parents


def literal_count(cube, n):
    return n - bin(cube[1]).count("1")


def minimum_cover(primes, ones, n):
    """Exact minimum cover: fewest terms, then fewest literals (deterministic)."""
    primes = sorted(primes)
    cov = {p: {m for m in ones if covers(p, m)} for p in primes}
    chosen, remaining = set(), set(ones)
    progress = True
    while progress and remaining:
        progress = False
        for m in sorted(remaining):
            ps = [p for p in primes if m in cov[p]]
            if len(ps) == 1 and ps[0] not in chosen:
                chosen.add(ps[0])
                remaining -= cov[ps[0]]
                progress = True
                break
    if remaining:
        cand = [p for p in primes if p not in chosen and cov[p] & remaining]
        for k in range(1, len(cand) + 1):
            best = None
            for combo in itertools.combinations(cand, k):
                if set().union(*(cov[p] for p in combo)) >= remaining:
                    cost = sum(literal_count(p, n) for p in combo)
                    if best is None or (cost, combo) < best:
                        best = (cost, combo)
            if best:
                chosen.update(best[1])
                break
    return sorted(chosen), cov


def minimize(ones, dcs, n):
    primes, parents = prime_implicants(ones + dcs)
    cover, cov = minimum_cover(primes, ones, n)
    # drop don't-care-only primes already excluded by cov & ones
    return {"primes": sorted(primes), "parents": parents, "cover": cover, "cov": cov}


# ------------------------------------------------------------ expressions
def cube_literals(cube, n, complement=False):
    """List of (var_index, polarity). polarity 1 = true literal."""
    value, mask = cube
    lits = []
    for i in range(n):
        bit = n - 1 - i
        if not (mask >> bit) & 1:
            pol = (value >> bit) & 1
            lits.append((i, 1 - pol if complement else pol))
    return lits


def fmt_lit(names, i, pol):
    return names[i] + ("" if pol else "'")


def fmt_product(lits, names):
    return "·".join(fmt_lit(names, i, p) for i, p in lits)


def fmt_sum(lits, names):
    return "(" + " + ".join(fmt_lit(names, i, p) for i, p in lits) + ")"


def sop_terms(cubes, n):          # product terms (list of literal lists)
    return [cube_literals(c, n) for c in cubes]


def pos_terms_from_complement(cubes_of_fn, n):  # sum terms of F from cubes of F'
    return [cube_literals(c, n, complement=True) for c in cubes_of_fn]


def minterm_terms(ms, n):
    return [cube_literals((m, 0), n) for m in ms]


def maxterm_terms(ms, n):
    return [cube_literals((m, 0), n, complement=True) for m in ms]


def expr_sop(terms, names):
    return " + ".join(fmt_product(t, names) for t in terms)


def expr_pos(terms, names):
    return "·".join(fmt_sum(t, names) for t in terms)


def verilog_lit(names, i, pol):
    return names[i] if pol else "~" + names[i]


def v_sop(terms, names):
    return " | ".join("(" + " & ".join(verilog_lit(names, i, p) for i, p in t) + ")" for t in terms)


def v_pos(terms, names):
    return " & ".join("(" + " | ".join(verilog_lit(names, i, p) for i, p in t) + ")" for t in terms)


def eval_terms(terms, assign, kind):
    if kind == "sop":
        return int(any(all(assign[i] == p for i, p in t) for t in terms))
    return int(all(any(assign[i] == p for i, p in t) for t in terms))


def assignment(m, n):
    return [(m >> (n - 1 - i)) & 1 for i in range(n)]


# ----------------------------------------------------------- netlist model
class Net:
    """Gate netlist of 1- and 2-input primitives with structural sharing."""

    def __init__(self, inputs):
        self.inputs = list(inputs)
        self.gates = []          # (op, out, ins)
        self.cache = {}
        self.tied = {}           # out -> src for tied-input inverters
        self.count = 0

    def gate(self, op, *ins):
        key = (op, ins if op == "not" else tuple(sorted(ins)))
        if key not in self.cache:
            self.count += 1
            out = f"n{self.count}"
            self.gates.append((op, out, list(ins)))
            self.cache[key] = out
        return self.cache[key]

    def neg(self, op, x):
        """Inverter built from a 2-input NAND/NOR with both inputs tied."""
        if x in self.tied:
            return self.tied[x]
        out = self.gate(op, x, x)
        self.tied[out] = x
        return out

    def evaluate(self, assign):
        val = dict(zip(self.inputs, assign))
        f = {"and": lambda a, b: a & b, "or": lambda a, b: a | b,
             "nand": lambda a, b: 1 - (a & b), "nor": lambda a, b: 1 - (a | b)}
        for op, out, ins in self.gates:
            val[out] = (1 - val[ins[0]]) if op == "not" else f[op](val[ins[0]], val[ins[1]])
        return val

    def counts(self):
        c = Counter(op for op, _, _ in self.gates)
        return dict(c)

    def total(self):
        return len(self.gates)

    def depth(self, outs):
        lvl = {i: 0 for i in self.inputs}
        for _, out, ins in self.gates:
            lvl[out] = 1 + max(lvl[i] for i in ins)
        return max(lvl[o] for o in outs)


def tree(net, op, items):
    """Balanced 2-input tree."""
    items = list(items)
    while len(items) > 1:
        nxt = [net.gate(op, items[i], items[i + 1]) for i in range(0, len(items) - 1, 2)]
        if len(items) % 2:
            nxt.append(items[-1])
        items = nxt
    return items[0]


def lit_net_not(net, names, i, pol):
    return names[i] if pol else net.gate("not", names[i])


def build_aoi(net, terms, names):
    """AND-OR-INV: NOT(OR of AND-terms). Returns the INVERTED sum-of-products."""
    prods = [tree(net, "and", [lit_net_not(net, names, i, p) for i, p in t]) for t in terms]
    return net.gate("not", tree(net, "or", prods))


def build_oai(net, terms, names):
    """OR-AND-INV: NOT(AND of OR-terms). Returns the INVERTED product-of-sums."""
    sums = [tree(net, "or", [lit_net_not(net, names, i, p) for i, p in t]) for t in terms]
    return net.gate("not", tree(net, "and", sums))


def build_universal(net, op, terms, names):
    """Two-level NAND-NAND (op='nand', product terms) or NOR-NOR (op='nor',
    sum terms) using ONLY 2-input gates; inverters are tied-input gates."""
    def lit(i, pol):
        return names[i] if pol else net.neg(op, names[i])

    def inner(items):      # NOT of the (AND for nand / OR for nor) combination
        if len(items) == 1:
            return net.neg(op, items[0])
        h = len(items) // 2
        return net.gate(op, comb(items[:h]), comb(items[h:]))

    def comb(items):
        if len(items) == 1:
            return items[0]
        return net.neg(op, inner(items))

    return inner([inner([lit(i, p) for i, p in t]) for t in terms])


# --------------------------------------------------------- analysis driver
def analyse(cfg):
    n, names = cfg["n"], cfg["variables"]
    ones, zeros, dcs = cfg["ones"], cfg["zeros"], cfg["dcs"]
    res = {"cfg": cfg}
    m_f = minimize(ones, dcs, n)         # SOP of F
    m_fn = minimize(zeros, dcs, n)       # SOP of F' (zeros are its ones)
    res["m_f"], res["m_fn"] = m_f, m_fn
    t = {}
    t["canon_sop_f"] = minterm_terms(ones, n)
    t["canon_pos_f"] = maxterm_terms(zeros, n)
    t["canon_sop_fn"] = minterm_terms(zeros, n)
    t["canon_pos_fn"] = maxterm_terms(ones, n)
    t["min_sop_f"] = sop_terms(m_f["cover"], n)
    t["min_sop_fn"] = sop_terms(m_fn["cover"], n)
    t["min_pos_f"] = pos_terms_from_complement(m_fn["cover"], n)   # F  = (F')'
    t["min_pos_fn"] = pos_terms_from_complement(m_f["cover"], n)   # F' = (F)'
    res["terms"] = t

    # ---- expression verification over every care input
    checks = 0
    for m in range(2 ** n):
        if m in dcs:
            continue
        a = assignment(m, n)
        fv = int(m in ones)
        for key, kind, want in (("canon_sop_f", "sop", fv), ("canon_pos_f", "pos", fv),
                                ("canon_sop_fn", "sop", 1 - fv), ("canon_pos_fn", "pos", 1 - fv),
                                ("min_sop_f", "sop", fv), ("min_pos_f", "pos", fv),
                                ("min_sop_fn", "sop", 1 - fv), ("min_pos_fn", "pos", 1 - fv)):
            got = eval_terms(t[key], a, kind)
            checks += 1
            if got != want:
                raise SystemExit(f"INTERNAL ERROR: {key} wrong at minterm {m}")
    res["expr_checks"] = checks

    # ---- networks for RTL (F and F' realised together, shared input inverters)
    nets = {}

    def mk(kind):
        net = Net(names)
        if kind == "aoi":      # F' = INV(SOP F), F = INV(SOP F')
            outs = {"fn": build_aoi(net, t["min_sop_f"], names), "f": build_aoi(net, t["min_sop_fn"], names)}
        elif kind == "oai":    # F' = INV(POS F), F = INV(POS F')
            outs = {"fn": build_oai(net, t["min_pos_f"], names), "f": build_oai(net, t["min_pos_fn"], names)}
        elif kind == "nand":
            outs = {"f": build_universal(net, "nand", t["min_sop_f"], names),
                    "fn": build_universal(net, "nand", t["min_sop_fn"], names)}
        else:
            outs = {"f": build_universal(net, "nor", t["min_pos_f"], names),
                    "fn": build_universal(net, "nor", t["min_pos_fn"], names)}
        return net, outs

    for kind in ("aoi", "oai", "nand", "nor"):
        net, outs = mk(kind)
        for m in range(2 ** n):
            if m in dcs:
                continue
            v = net.evaluate(assignment(m, n))
            fv = int(m in ones)
            if v[outs["f"]] != fv or v[outs["fn"]] != 1 - fv:
                raise SystemExit(f"INTERNAL ERROR: {kind} network wrong at minterm {m}")
        nets[kind] = (net, outs)
    res["nets"] = nets

    # ---- candidate comparison (each network built standalone for ONE output)
    cands = {}
    for polarity, key_sop, key_pos, other_sop, other_pos, canon_sop, canon_pos in (
            ("F", "min_sop_f", "min_pos_f", "min_sop_fn", "min_pos_fn", "canon_sop_f", "canon_pos_f"),
            ("F'", "min_sop_fn", "min_pos_fn", "min_sop_f", "min_pos_f", "canon_sop_fn", "canon_pos_fn")):
        rows = []

        def standalone(op, terms, invert=False):
            net = Net(names)
            out = build_universal(net, op, terms, names)
            if invert:
                out = net.neg(op, out)
            return net, out

        for label, op, terms, inv in (
                ("NAND-NAND from minimal SOP", "nand", t[key_sop], False),
                ("NAND-NAND of the complement's minimal SOP + 1 inverter", "nand", t[other_sop], True),
                ("NAND-NAND from canonical SOP (unminimized)", "nand", t[canon_sop], False),
                ("NOR-NOR from minimal POS", "nor", t[key_pos], False),
                ("NOR-NOR of the complement's minimal POS + 1 inverter", "nor", t[other_pos], True),
                ("NOR-NOR from canonical POS (unminimized)", "nor", t[canon_pos], False)):
            net, out = standalone(op, terms, inv)
            ok = all(net.evaluate(assignment(m, n))[out] == (int(m in ones) if polarity == "F" else 1 - int(m in ones))
                     for m in range(2 ** n) if m not in dcs)
            if not ok:
                raise SystemExit(f"INTERNAL ERROR: candidate '{label}' for {polarity} is wrong")
            rows.append({"label": label, "gates": net.total(), "op": op.upper(), "depth": net.depth([out]),
                         "inverters": len(net.tied)})
        cands[polarity] = rows
    res["cands"] = cands
    return res


# ------------------------------------------------------- Verilog emission
def hexw(bits):
    return f"{len(bits)}'h{int(''.join(map(str, bits)), 2):0{(len(bits) + 3) // 4}x}"


def emit_net_module(modname, cfg, net, outs, comment):
    names, o = cfg["variables"], cfg["outputs"]
    port_of = {outs["f"]: o["f"], outs["fn"]: o["fn"]}
    rename, assigns = {}, []
    for key in ("f", "fn"):
        nid = outs[key]
        if nid in names or nid in rename:
            assigns.append((o[key], nid))
        else:
            rename[nid] = o[key]
    r = lambda x: rename.get(x, x)
    wires = sorted({out for _, out, _ in net.gates if out not in rename}, key=lambda s: int(s[1:]))
    L = [f"// {comment}", f"module {modname} ("]
    L.append("    " + ", ".join(f"input {v}" for v in names) + ",")
    L.append(f"    output {o['f']},")
    L.append(f"    output {o['fn']}")
    L.append(");")
    if wires:
        L.append("    wire " + ", ".join(wires) + ";")
    for i, (op, out, ins) in enumerate(net.gates, 1):
        L.append(f"    {op} g{i} ({', '.join(r(x) for x in [out] + ins)});")
    for dst, src in assigns:
        L.append(f"    assign {dst} = {r(src)};")
    L.append("endmodule\n")
    return "\n".join(L)


def tt_bits(cfg, which):
    """Table for MUX/decoder realisation. Don't-cares resolved to 0."""
    n = cfg["n"]
    bits = []
    for m in range(2 ** n):
        if m in cfg["dcs"]:
            bits.append(0)
        else:
            bits.append(int(m in cfg["ones"]) if which == "f" else int(m not in cfg["ones"]))
    return bits


def emit_rtl(cfg, res):
    n, names, o, name = cfg["n"], cfg["variables"], cfg["outputs"], cfg["name"]
    t, nets = res["terms"], res["nets"]
    ports_in = ", ".join(f"input {v}" for v in names)
    L = [f"// GENERATED by tools/boolean_design/boolean_design.py from {cfg.get('_config_rel', 'config')}",
         "// Do not edit by hand - regenerate instead.",
         f"// Function: {cfg.get('description', name)}",
         f"// Variable order (MSB first): {', '.join(names)};  minterm index = {{{', '.join(names)}}}",
         f"// Minterms (F=1): {cfg['ones']}   Don't-cares: {cfg['dcs']}"]
    if cfg.get("is_demonstration"):
        L.append("// DEMONSTRATION FUNCTION - not a student's assigned registration-number function.")
    L.append("")
    # behavioral
    L.append("// Behavioral: truth-table case statement (don't-care rows output x)")
    L.append(f"module {name}_bh ({ports_in}, output reg {o['f']}, output reg {o['fn']});")
    L.append("    always @* begin")
    L.append(f"        case ({{{', '.join(names)}}})")
    for m in range(2 ** n):
        if m in cfg["dcs"]:
            fv, fnv = "1'bx", "1'bx"
        else:
            fv, fnv = (f"1'b{int(m in cfg['ones'])}", f"1'b{int(m not in cfg['ones'])}")
        L.append(f"            {n}'d{m}: begin {o['f']} = {fv}; {o['fn']} = {fnv}; end")
    L.append(f"            default: begin {o['f']} = 1'bx; {o['fn']} = 1'bx; end")
    L.append("        endcase\n    end\nendmodule\n")
    # dataflow
    L.append("// Dataflow: minimal SOP expressions (F' has its own minimal SOP)")
    L.append(f"module {name}_df ({ports_in}, output {o['f']}, output {o['fn']});")
    L.append(f"    assign {o['f']}  = {v_sop(t['min_sop_f'], names)};")
    L.append(f"    assign {o['fn']} = {v_sop(t['min_sop_fn'], names)};")
    L.append("endmodule\n")
    # structural gate networks
    descr = {"aoi": "AND-OR-INV (SOP): F' = INV(SOP of F), F = INV(SOP of F'); 2-input AND/OR + NOT",
             "oai": "OR-AND-INV (POS): F' = INV(POS of F), F = INV(POS of F'); 2-input OR/AND + NOT",
             "nand": "NAND-NAND (SOP): two-input NAND only, inverters = NAND with tied inputs",
             "nor": "NOR-NOR (POS): two-input NOR only, inverters = NOR with tied inputs"}
    for kind in ("aoi", "oai", "nand", "nor"):
        net, outs = nets[kind]
        L.append(emit_net_module(f"{name}_{kind}", cfg, net, outs, descr[kind]))
    # MUX / decoder realisations (n <= 4)
    if n <= MAX_HW_VARS:
        pad = 4 - n
        sel = "{" + (f"{pad}'b0, " if pad else "") + ", ".join(names) + "}"
        d_f = hexw(list(reversed(tt_bits(cfg, "f") + [0] * (16 - 2 ** n))))
        d_fn = hexw(list(reversed(tt_bits(cfg, "fn") + [0] * (16 - 2 ** n))))
        L.append("// 16:1 multiplexer: data inputs are the truth-table column, select = variables")
        L.append(f"// (d[i] is the output for minterm i; don't-cares tied to 0)")
        L.append(f"module {name}_mux16 ({ports_in}, output {o['f']}, output {o['fn']});")
        L.append(f"    mux16 m_f  (.d({d_f}), .s({sel}), .y({o['f']}));")
        L.append(f"    mux16 m_fn (.d({d_fn}), .s({sel}), .y({o['fn']}));")
        L.append("endmodule\n")
        # 8:1 MUX, last variable is the data (variable-entered MUX)
        sel8_vars = names[:-1]
        pad8 = 3 - len(sel8_vars)
        sel8 = "{" + (f"{pad8}'b0, " if pad8 else "") + ", ".join(sel8_vars) + "}"
        last = names[-1]

        def d8(which):
            bits = tt_bits(cfg, which)
            ent = []
            for k in range(2 ** (n - 1)):
                a, b = bits[2 * k], bits[2 * k + 1]
                ent.append({(0, 0): "1'b0", (1, 1): "1'b1", (0, 1): last, (1, 0): f"~{last}"}[(a, b)])
            ent += ["1'b0"] * (8 - len(ent))
            return "{" + ", ".join(reversed(ent)) + "}"
        L.append("// 8:1 multiplexer (variable-entered): selects = all variables but the last;")
        L.append(f"// data input k is one of 0, 1, {last}, ~{last} depending on rows 2k and 2k+1")
        L.append(f"module {name}_mux8 ({ports_in}, output {o['f']}, output {o['fn']});")
        L.append(f"    mux8 m_f  (.d({d8('f')}), .s({sel8}), .y({o['f']}));")
        L.append(f"    mux8 m_fn (.d({d8('fn')}), .s({sel8}), .y({o['fn']}));")
        L.append("endmodule\n")
        L.append("// 4:16 decoder + OR of minterm lines (F = OR of lines where F=1, F' = OR where F=0;")
        L.append("// don't-care lines feed neither output)")
        L.append(f"module {name}_dec ({ports_in}, output {o['f']}, output {o['fn']});")
        L.append("    wire [15:0] y;")
        L.append(f"    decoder4to16 dec (.a({sel}), .en(1'b1), .y(y));")
        L.append(f"    assign {o['f']}  = " + " | ".join(f"y[{m}]" for m in cfg["ones"]) + ";")
        L.append(f"    assign {o['fn']} = " + " | ".join(f"y[{m}]" for m in cfg["zeros"]) + ";")
        L.append("endmodule\n")
    return "\n".join(L)


def emit_tb(cfg):
    n, names, o, name = cfg["n"], cfg["variables"], cfg["outputs"], cfg["name"]
    impls = ["bh", "df", "aoi", "oai", "nand", "nor"] + (["mux16", "mux8", "dec"] if n <= MAX_HW_VARS else [])
    exp = hexw(list(reversed([int(m in cfg["ones"]) for m in range(2 ** n)])))
    care = hexw(list(reversed([int(m not in cfg["dcs"]) for m in range(2 ** n)])))
    L = [f"// GENERATED by tools/boolean_design/boolean_design.py - do not edit by hand.",
         f"// Exhaustive self-checking test for {name}: every implementation vs the truth table",
         "// taken straight from the configuration (not from the minimized expressions).",
         "`timescale 1ns/1ps", f"module tb_{name};"]
    L.append("    reg " + ", ".join(names) + ";")
    for k in impls:
        L.append(f"    wire f_{k}, fn_{k};")
    for k in impls:
        conn = ", ".join(f".{v}({v})" for v in names)
        L.append(f"    {name}_{k} u_{k} ({conn}, .{o['f']}(f_{k}), .{o['fn']}(fn_{k}));")
    L.append(f"    localparam [{2 ** n - 1}:0] EXP_F = {exp};")
    L.append(f"    localparam [{2 ** n - 1}:0] CARE  = {care};")
    L.append("    integer errors, tests, idx;")
    L.append("    reg [8*256-1:0] vcdfile;")
    L.append("    task check;")
    L.append("        input [8*8-1:0] who;")
    L.append("        input got_f, got_fn;")
    L.append("        begin")
    L.append("            tests = tests + 1;")
    L.append("            if (got_f !== EXP_F[idx] || got_fn !== ~EXP_F[idx]) begin")
    L.append("                errors = errors + 1;")
    L.append(f"                $display(\"FAIL %0s minterm=%0d got {o['f']}=%b {o['fn']}=%b expected {o['f']}=%b {o['fn']}=%b\",")
    L.append("                         who, idx, got_f, got_fn, EXP_F[idx], ~EXP_F[idx]);")
    L.append("            end")
    L.append("            tests = tests + 1;     // complement relation")
    L.append("            if (got_f === got_fn) begin")
    L.append("                errors = errors + 1;")
    L.append("                $display(\"FAIL %0s minterm=%0d F and F' are not complementary\", who, idx);")
    L.append("            end")
    L.append("        end")
    L.append("    endtask")
    L.append("    initial begin")
    L.append("        if ($value$plusargs(\"vcd=%s\", vcdfile)) begin")
    L.append("            $dumpfile(vcdfile);")
    L.append(f"            $dumpvars(0, tb_{name});")
    L.append("        end")
    L.append("        errors = 0; tests = 0;")
    L.append(f"        for (idx = 0; idx < {2 ** n}; idx = idx + 1) begin")
    L.append(f"            {{{', '.join(names)}}} = idx[{n - 1}:0];")
    L.append("            #5;")
    L.append("            if (CARE[idx]) begin")
    for k in impls:
        L.append(f"                check(\"{k}\", f_{k}, fn_{k});")
    L.append("            end")
    L.append("            #5;")
    L.append("        end")
    L.append("        if (errors == 0) $display(\"RESULT: PASS tests=%0d\", tests);")
    L.append("        else             $display(\"RESULT: FAIL errors=%0d tests=%0d\", errors, tests);")
    L.append("        $finish;")
    L.append("    end")
    L.append("endmodule")
    return "\n".join(L) + "\n"


# ---------------------------------------------------------------- K-map
def kmap_layout(n):
    rb = n // 2
    cb = n - rb
    gray = lambda k: k ^ (k >> 1)
    rows = [gray(i) for i in range(2 ** rb)]
    cols = [gray(i) for i in range(2 ** cb)]
    return rb, cb, rows, cols


def kmap_text(cfg, ones_set, label_cube_groups=None):
    n, names = cfg["n"], cfg["variables"]
    if n > 4:
        return None
    rb, cb, rows, cols = kmap_layout(n)
    rv, cv = "".join(names[:rb]), "".join(names[rb:])
    hdr = f"| {rv}\\{cv} | " + " | ".join(format(c, f"0{cb}b") for c in cols) + " |"
    sep = "|---|" + "---|" * len(cols)
    lines = [hdr, sep]
    for r in rows:
        cells = []
        for c in cols:
            m = (r << cb) | c
            cells.append("X" if m in cfg["dcs"] else ("1" if m in ones_set else "0"))
        lines.append(f"| **{format(r, f'0{rb}b')}** | " + " | ".join(cells) + " |")
    return "\n".join(lines)


PALETTE = ["#d55e00", "#0072b2", "#009e73", "#cc79a7", "#e69f00", "#56b4e9", "#6a3d9a", "#8c564b"]


def kmap_svg_panel(cfg, ones_set, cubes, x0, y0, title):
    n, names = cfg["n"], cfg["variables"]
    rb, cb, rows, cols = kmap_layout(n)
    cell = 54
    out = [f'<text x="{x0}" y="{y0 - 34}" font-size="15" font-weight="bold" fill="#111">{escape(title)}</text>']
    out.append(f'<text x="{x0 - 6}" y="{y0 - 8}" font-size="12" text-anchor="end" fill="#333">'
               f'{escape("".join(names[:rb]) + chr(92) + "".join(names[rb:]))}</text>')
    for j, c in enumerate(cols):
        out.append(f'<text x="{x0 + j * cell + cell / 2}" y="{y0 - 8}" font-size="12" text-anchor="middle" fill="#333">{format(c, f"0{cb}b")}</text>')
    for i, r in enumerate(rows):
        out.append(f'<text x="{x0 - 8}" y="{y0 + i * cell + cell / 2 + 4}" font-size="12" text-anchor="end" fill="#333">{format(r, f"0{rb}b")}</text>')
        for j, c in enumerate(cols):
            m = (r << cb) | c
            v = "X" if m in cfg["dcs"] else ("1" if m in ones_set else "0")
            out.append(f'<rect x="{x0 + j * cell}" y="{y0 + i * cell}" width="{cell}" height="{cell}" fill="#fff" stroke="#555"/>')
            out.append(f'<text x="{x0 + j * cell + cell / 2}" y="{y0 + i * cell + cell / 2 + 5}" font-size="16" text-anchor="middle" fill="#111">{v}</text>')
            out.append(f'<text x="{x0 + j * cell + 4}" y="{y0 + i * cell + 12}" font-size="9" fill="#777">m{m}</text>')
    for gi, cube in enumerate(cubes):
        col = PALETTE[gi % len(PALETTE)]
        inset = 3 + 3 * (gi % 4)
        for m in range(2 ** n):
            if covers(cube, m):
                r_i = rows.index(m >> cb)
                c_i = cols.index(m & (2 ** cb - 1))
                out.append(f'<rect x="{x0 + c_i * cell + inset}" y="{y0 + r_i * cell + inset}" width="{cell - 2 * inset}" '
                           f'height="{cell - 2 * inset}" rx="8" fill="{col}" fill-opacity="0.12" stroke="{col}" stroke-width="2"/>')
    return out


def kmap_svg(cfg, res):
    n, names = cfg["n"], cfg["variables"]
    if n > 4:
        return None
    t = res["terms"]
    cell, w_panel = 54, 54 * (2 ** (n - n // 2))
    h_panel = 54 * (2 ** (n // 2))
    W = 2 * w_panel + 260
    legend_rows = max(len(res["m_f"]["cover"]), len(res["m_fn"]["cover"]))
    H = h_panel + 170 + 20 * legend_rows
    o = []
    o.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}" font-family="Helvetica, Arial, sans-serif" role="img">')
    o.append(f'<title>K-maps for {escape(cfg["name"])}</title>')
    o.append(f'<desc>Karnaugh maps of F (ones grouped) and F\' (zeros grouped) for {escape(cfg["name"])}. '
             f'Generated from the configuration by boolean_design.py.</desc>')
    o.append(f'<rect width="{W}" height="{H}" fill="#fff"/>')
    ttl = "Illustrative DEMONSTRATION function" if cfg.get("is_demonstration") else "Configured function"
    o.append(f'<text x="20" y="24" font-size="16" font-weight="bold" fill="#111">{escape(ttl)}: {escape(cfg["name"])}</text>')
    o.append(f'<text x="20" y="44" font-size="13" fill="#333">F({", ".join(names)}) = Σm({", ".join(map(str, cfg["ones"]))})'
             f'{(" + d(" + ", ".join(map(str, cfg["dcs"])) + ")") if cfg["dcs"] else ""}</text>')
    x1, x2, y0 = 70, 70 + w_panel + 120, 104
    o += kmap_svg_panel(cfg, set(cfg["ones"]), res["m_f"]["cover"], x1, y0, "F: groups of 1s (minimal SOP of F)")
    o += kmap_svg_panel(cfg, set(cfg["zeros"]), res["m_fn"]["cover"], x2, y0, "F': groups of 0s of F (minimal SOP of F')")
    ly = y0 + h_panel + 36
    for gi, c in enumerate(res["m_f"]["cover"]):
        col = PALETTE[gi % len(PALETTE)]
        o.append(f'<rect x="{x1}" y="{ly + gi * 20 - 11}" width="12" height="12" rx="3" fill="{col}"/>')
        o.append(f'<text x="{x1 + 20}" y="{ly + gi * 20}" font-size="13" fill="#111">{escape(fmt_product(cube_literals(c, n), names))}</text>')
    for gi, c in enumerate(res["m_fn"]["cover"]):
        col = PALETTE[gi % len(PALETTE)]
        o.append(f'<rect x="{x2}" y="{ly + gi * 20 - 11}" width="12" height="12" rx="3" fill="{col}"/>')
        o.append(f'<text x="{x2 + 20}" y="{ly + gi * 20}" font-size="13" fill="#111">{escape(fmt_product(cube_literals(c, n), names))}</text>')
    yy = ly + legend_rows * 20 + 20
    o.append(f'<text x="{x1}" y="{yy}" font-size="14" fill="#111">F = {escape(expr_sop(t["min_sop_f"], names))}</text>')
    o.append(f'<text x="{x2}" y="{yy}" font-size="14" fill="#111">F\' = {escape(expr_sop(t["min_sop_fn"], names))}</text>')
    o.append(f'<text x="{x1}" y="{yy + 22}" font-size="12" fill="#555">X = don\'t-care. Outlines are drawn per cell (wrap-around groups are shown on every covered cell).</text>')
    o.append("</svg>")
    return "\n".join(o) + "\n"


# --------------------------------------------------------------- reports
def merge_story(cube, parents, n, names):
    """Explain how a prime implicant arises by the combining theorem X.Y + X.Y' = X.

    Every merge in the derivation tree of `cube` is listed once, top-down.
    """
    lines, seen = [], set()

    def rec(c):
        if c not in parents or c in seen:
            return
        seen.add(c)
        a, b, bit = parents[c]
        vi = n - bit.bit_length()
        lines.append(f"`{fmt_product(cube_literals(a, n), names)}` + `{fmt_product(cube_literals(b, n), names)}` "
                     f"= `{fmt_product(cube_literals(c, n), names) or '1'}` (variable {names[vi]} eliminated: "
                     f"X·{names[vi]} + X·{names[vi]}' = X)")
        rec(a)
        rec(b)
    rec(cube)
    return lines


def report_markdown(cfg, res, rtl_files, rel):
    n, names, o = cfg["n"], cfg["variables"], cfg["outputs"]
    t, ones, zeros, dcs = res["terms"], cfg["ones"], cfg["zeros"], cfg["dcs"]
    L = [f"# Boolean analysis: `{cfg['name']}`", "",
         "<!-- GENERATED by tools/boolean_design/boolean_design.py - do not edit by hand -->", ""]
    if cfg.get("is_demonstration"):
        L += ["> **DEMONSTRATION FUNCTION.** This is an illustrative function chosen to exercise the toolchain. "
              "It is **not** any student's assigned registration-number function. The course sheets do not "
              "define a rule that maps a registration number to minterms, so none is assumed here.", ""]
    L += [f"* Config: `{rel}`", f"* Description: {cfg.get('description', '-')}",
          f"* Variables (MSB first): {', '.join(names)} - minterm index = binary number `{''.join(names)}`",
          f"* Outputs: `{o['f']}` = F, `{o['fn']}` = F'",
          f"* Minterms (F=1): {ones}", f"* Maxterms (F=0): {zeros}", f"* Don't-cares: {dcs if dcs else 'none'}",
          f"* Mapping rule from registration number: {json.dumps(cfg.get('mapping_rule')) if cfg.get('mapping_rule') else '**not defined** (minterms were supplied directly)'}", ""]
    L += ["## 1. Truth table", "", "| m | " + " | ".join(names) + f" | {o['f']} (F) | {o['fn']} (F') |",
          "|---|" + "---|" * (n + 2)]
    for m in range(2 ** n):
        bits = assignment(m, n)
        fv = "X" if m in dcs else str(int(m in ones))
        fn = "X" if m in dcs else str(int(m not in ones))
        L.append(f"| {m} | " + " | ".join(map(str, bits)) + f" | {fv} | {fn} |")
    L += ["", "## 2. Canonical forms (don't-cares are not listed)", ""]
    sig = lambda ms: ", ".join(map(str, ms))
    L += [f"* F  = Σm({sig(ones)}) = {expr_sop(t['canon_sop_f'], names)}",
          f"* F  = ΠM({sig(zeros)}) = {expr_pos(t['canon_pos_f'], names)}",
          f"* F' = Σm({sig(zeros)}) = {expr_sop(t['canon_sop_fn'], names)}",
          f"* F' = ΠM({sig(ones)}) = {expr_pos(t['canon_pos_fn'], names)}", ""]
    L += ["## 3. Minimal forms (Quine-McCluskey, exact cover)", "",
          "Selection criterion: fewest product/sum terms, then fewest literals. Minimal under *that criterion* "
          "for two-level forms; this is not a claim about multi-level or gate-count-optimal circuits.", ""]
    L += [f"* F  (SOP) = {expr_sop(t['min_sop_f'], names)}", f"* F  (POS) = {expr_pos(t['min_pos_f'], names)}",
          f"* F' (SOP) = {expr_sop(t['min_sop_fn'], names)}", f"* F' (POS) = {expr_pos(t['min_pos_fn'], names)}", "",
          "POS forms come from De Morgan's law applied to the minimal SOP of the complement: "
          "F = (F')' = Π(complemented-literal sums).", ""]
    L += ["## 4. Karnaugh maps", ""]
    km = kmap_text(cfg, set(ones))
    if km:
        L += ["K-map of F (X = don't-care):", "", km, "",
              f"![K-map]({'../../assets/diagrams/kmap_' + cfg['name'] + '.svg'})", "",
              f"*Figure: K-maps of F and F' for `{cfg['name']}` (generated; relative path "
              f"`assets/diagrams/kmap_{cfg['name']}.svg`).*", ""]
    else:
        L += [f"K-map drawing is provided for up to 4 variables; this function has {n}. "
              "Minimal forms above were obtained algebraically by Quine-McCluskey.", ""]
    L += ["## 5. Boolean-law justification of each prime implicant", "",
          "Each prime implicant is built by repeatedly applying the combining theorem "
          "`X·Y + X·Y' = X` to pairs of terms that differ in one variable. The steps below are the actual "
          "merges performed by the tool (not a free-form proof); equivalence of the final expressions with "
          "the truth table is verified exhaustively (section 7).", ""]
    for title, key in (("F", "m_f"), ("F'", "m_fn")):
        L.append(f"**{title}**")
        L.append("")
        for c in res[key]["cover"]:
            L.append(f"* Selected term `{fmt_product(cube_literals(c, n), names)}` covers minterms "
                     f"{sorted(m for m in range(2 ** n) if covers(c, m))}")
            for s in merge_story(c, res[key]["parents"], n, names):
                L.append(f"    * {s}")
        L.append("")
    L += ["## 6. Gate-level networks (two-input gates only)", "",
          "Conventions: inputs are available in **true form only**; every complemented literal needs an inverter "
          "(counted once and shared inside a network). Wide terms are decomposed into balanced trees of "
          "two-input gates. In NAND-only/NOR-only networks an inverter is a two-input gate with tied inputs and "
          "counts as one gate. `F` and `F'` are built together, sharing input inverters. "
          "AOI/OAI networks end in the INV that produces the complement.", ""]
    L += ["| Network | Realizes | Gate counts | Total gates | Depth |", "|---|---|---|---|---|"]
    desc = {"aoi": ("AND-OR-INV", "F' from SOP(F); F from SOP(F')"),
            "oai": ("OR-AND-INV", "F' from POS(F); F from POS(F')"),
            "nand": ("NAND-NAND", "F from SOP(F); F' from SOP(F')"),
            "nor": ("NOR-NOR", "F from POS(F); F' from POS(F')")}
    for kind in ("aoi", "oai", "nand", "nor"):
        net, outs = res["nets"][kind]
        cnt = ", ".join(f"{k.upper()}: {v}" for k, v in sorted(net.counts().items()))
        L.append(f"| {desc[kind][0]} (`{cfg['name']}_{kind}`) | {desc[kind][1]} | {cnt} | {net.total()} | "
                 f"{net.depth(list(outs.values()))} |")
    L += ["", "### Candidate comparison (each circuit realises ONE output on its own)", "",
          "These are the circuits actually constructed and verified by the tool. The smallest one *among those "
          "evaluated* is marked; no global-optimality claim is made.", ""]
    for pol in ("F", "F'"):
        rows = res["cands"][pol]
        best_nand = min(r["gates"] for r in rows if r["op"] == "NAND")
        best_nor = min(r["gates"] for r in rows if r["op"] == "NOR")
        L += [f"**Output {pol}**", "", "| Candidate | Gates (2-input) | of which inverters | Depth | Smallest of its type |",
              "|---|---|---|---|---|"]
        for r in rows:
            best = best_nand if r["op"] == "NAND" else best_nor
            L.append(f"| {r['label']} | {r['gates']} | {r['inverters']} | {r['depth']} | {'yes' if r['gates'] == best else ''} |")
        L.append("")
    L += ["Reading the table: the unminimized canonical-form rows show the benefit of minimization; "
          "the 'complement + 1 inverter' rows show whether building the opposite polarity and inverting is "
          "cheaper than the direct network.", ""]
    L += ["## 7. Verification performed by the tool", "",
          f"* {res['expr_checks']} expression evaluations (8 expressions x all care minterms) matched the truth table.",
          "* The AOI, OAI, NAND-NAND and NOR-NOR netlists were simulated in Python for every care input; "
          "F and F' were complementary on every care input.",
          "* The generated Verilog is verified separately by simulation: "
          f"`python scripts/run_tests.py --test tb_{cfg['name']}`.", ""]
    L += ["## 8. Generated files", ""] + [f"* `{f}`" for f in rtl_files] + [""]
    return "\n".join(L)


def truth_table_markdown(cfg):
    n, names, o = cfg["n"], cfg["variables"], cfg["outputs"]
    L = [f"# Truth table: `{cfg['name']}`", "",
         "<!-- GENERATED by tools/boolean_design/boolean_design.py - do not edit by hand -->", ""]
    if cfg.get("is_demonstration"):
        L += ["> Demonstration function, not a student's assigned function.", ""]
    L += ["| m | " + " | ".join(names) + f" | {o['f']} | {o['fn']} |", "|---|" + "---|" * (n + 2)]
    for m in range(2 ** n):
        fv = "X" if m in cfg["dcs"] else str(int(m in cfg["ones"]))
        fn = "X" if m in cfg["dcs"] else str(int(m not in cfg["ones"]))
        L.append(f"| {m} | " + " | ".join(map(str, assignment(m, n))) + f" | {fv} | {fn} |")
    return "\n".join(L) + "\n"


def gate_doc_markdown(cfg, res):
    L = [f"# Gate-count analysis: `{cfg['name']}`", "",
         "<!-- GENERATED by tools/boolean_design/boolean_design.py - do not edit by hand -->", ""]
    if cfg.get("is_demonstration"):
        L += ["> Demonstration function, not a student's assigned function.", ""]
    L += ["Counts are for the Verilog netlists emitted into `examples/registration-function/"
          f"{cfg['name']}/`; they are cross-checked below by counting primitive instances in the generated "
          "Verilog source.", ""]
    L += ["| Module | Primitive instances found in generated Verilog | Tool's netlist model |", "|---|---|---|"]
    return L


# ------------------------------------------------------------ generation
def generate(cfg_path, out_root, docs_root, assets_root):
    cfg = load_config(cfg_path)
    try:
        cfg["_config_rel"] = str(Path(cfg_path).resolve().relative_to(ROOT))
    except ValueError:
        cfg["_config_rel"] = Path(cfg_path).name
    res = analyse(cfg)
    name = cfg["name"]
    ex = out_root / name
    ex.mkdir(parents=True, exist_ok=True)
    files = {}
    rtl_text = emit_rtl(cfg, res)
    files[ex / f"{name}_rtl.v"] = rtl_text
    files[ex / f"tb_{name}.v"] = emit_tb(cfg)

    # cross-check gate counts: Verilog source vs Python model
    gl = gate_doc_markdown(cfg, res)
    for kind in ("aoi", "oai", "nand", "nor"):
        net, _ = res["nets"][kind]
        c = count_primitives(rtl_text, f"{name}_{kind}")
        if sum(c.values()) != net.total() or dict(c) != net.counts():
            raise SystemExit(f"INTERNAL ERROR: gate count mismatch in {name}_{kind}")
        gl.append(f"| `{name}_{kind}` | {', '.join(f'{k.upper()}: {v}' for k, v in sorted(c.items()))} "
                  f"(total {sum(c.values())}) | {net.total()} - match |")
    gl.append("")
    rep = report_markdown(cfg, res, [], cfg["_config_rel"])
    # reuse candidate/network section for the gate doc
    start = rep.index("## 6. Gate-level networks")
    end = rep.index("## 7. Verification")
    gl.append(rep[start:end])
    files[docs_root / "gate-count-analysis" / f"{name}_gate_counts.md"] = "\n".join(gl) + "\n"
    files[docs_root / "truth-tables" / f"{name}_truth_table.md"] = truth_table_markdown(cfg)
    svg = kmap_svg(cfg, res)
    gen_list = [str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else p.name for p in files]
    if svg:
        files[assets_root / "diagrams" / f"kmap_{name}.svg"] = svg
        gen_list.append(f"assets/diagrams/kmap_{name}.svg")
    gen_list.append(f"docs/boolean-derivations/{name}.md")
    files[docs_root / "boolean-derivations" / f"{name}.md"] = report_markdown(cfg, res, gen_list, cfg["_config_rel"])
    return files, res


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--config", required=True)
    ap.add_argument("--check", action="store_true", help="fail if committed outputs differ from regenerated ones")
    ap.add_argument("--summary", action="store_true", help="print the minimal expressions")
    args = ap.parse_args()

    files, res = generate(args.config, ROOT / "examples" / "registration-function",
                          ROOT / "docs", ROOT / "assets")
    cfg = res["cfg"]
    if args.summary or not args.check:
        t, names = res["terms"], cfg["variables"]
        print(f"{cfg['name']}: F = {expr_sop(t['min_sop_f'], names)}   F' = {expr_sop(t['min_sop_fn'], names)}")
        for kind in ("aoi", "oai", "nand", "nor"):
            print(f"  {kind:5s} network: {res['nets'][kind][0].total()} two-input gates")
    if args.check:
        stale = [p for p, txt in files.items() if not p.exists() or p.read_text() != txt]
        if stale:
            print("STALE generated files (run without --check):", file=sys.stderr)
            for p in stale:
                print("  ", p.relative_to(ROOT), file=sys.stderr)
            return 1
        print(f"{cfg['name']}: generated files up to date ({len(files)} files)")
        return 0
    for p, txt in files.items():
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(txt)
        print("wrote", p.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
