// 2:1 multiplexer, Y = S ? D1 : D0  (S=0 selects D0, S=1 selects D1).
// Plain name = dataflow (used as the building block of larger MUXes).
// _bh behavioral, _sop / _pos / _nand / _nor are gate-level realizations of
// the same equation  Y = (~S.D0) + (S.D1)  =  (D0+S).(~S+D1).

module mux2 (input d0, input d1, input s, output y);
    assign y = s ? d1 : d0;
endmodule

module mux2_bh (input d0, input d1, input s, output reg y);
    always @* begin
        if (s) y = d1;
        else   y = d0;
    end
endmodule

// SOP: AND-OR  (1 inverter + 2 AND + 1 OR)
module mux2_sop (input d0, input d1, input s, output y);
    wire ns, t0, t1;
    not g0 (ns, s);
    and g1 (t0, ns, d0);
    and g2 (t1, s, d1);
    or  g3 (y, t0, t1);
endmodule

// POS: OR-AND
module mux2_pos (input d0, input d1, input s, output y);
    wire ns, t0, t1;
    not g0 (ns, s);
    or  g1 (t0, s, d0);
    or  g2 (t1, ns, d1);
    and g3 (y, t0, t1);
endmodule

// NAND-only (inverter = NAND with tied inputs): 4 gates
module mux2_nand (input d0, input d1, input s, output y);
    wire ns, t0, t1;
    nand g0 (ns, s, s);
    nand g1 (t0, ns, d0);
    nand g2 (t1, s, d1);
    nand g3 (y, t0, t1);
endmodule

// NOR-only: 4 gates  y = nor( nor(d0,s), nor(~s,d1) ) = (d0+s).(~s+d1)
// (~s via a NOR with tied inputs)
module mux2_nor (input d0, input d1, input s, output y);
    wire ns, t0, t1;
    nor g0 (ns, s, s);
    nor g1 (t0, d0, s);
    nor g2 (t1, ns, d1);
    nor g3 (y, t0, t1);
endmodule
