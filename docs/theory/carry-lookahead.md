# Carry-lookahead addition

In a ripple adder each carry waits for the one before it. Define for each bit generate `g = a·b` (this bit creates a carry) and propagate `p = a ⊕ b` (this bit passes an incoming carry on). Then `c[i+1] = g[i] + p[i]·c[i]`. Substituting repeatedly gives each carry as a function of the g, p and cin only, e.g. `c2 = g1 + p1·g0 + p1·p0·cin`, so all carries are produced in parallel (two gate levels after p/g) and `sum[i] = p[i] ⊕ c[i]`.

Trade-off: gate fan-in and wiring grow quickly with width, so practical adders use 4-bit lookahead blocks and a second-level lookahead using group `P = ∏p` and `G` (implemented in `cla_adder16`). Equations, block diagram and tests: [Task IV](../task04-alu-fpga.md).
