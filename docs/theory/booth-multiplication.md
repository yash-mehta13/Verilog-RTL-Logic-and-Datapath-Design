# Booth multiplication

Booth's idea: recode the multiplier so a run of 1s is handled as `+2^k - 2^j` instead of many additions. Examining pairs `(Q_i, Q_{i-1})`: `01` → add the multiplicand, `10` → subtract it, `00`/`11` → no operation; after each step shift the partial product right arithmetically. Because the recoding works on two's-complement bits directly, signed operands need no sign correction.

Steps used here (radix-2, N steps): initialise `A=0`, `Q=multiplier`, `Q_-1=0`; repeat N times {recode, add/subtract M, arithmetic shift right `{A,Q,Q_-1}`}; product = `{A, Q}` (2N bits). Worked example (-3 × 5), flowchart and datapath: [Task IV](../task04-alu-fpga.md). Limitation of radix-2: worst-case alternating bit patterns still need up to N add/subtract operations; radix-4 recoding halves the number of steps.
