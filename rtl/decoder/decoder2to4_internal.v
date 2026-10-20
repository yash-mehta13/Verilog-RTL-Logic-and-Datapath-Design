// Internal gate-level realizations of a 2:4 decoder (no enable).
// Output polarity is part of the module name suffix semantics:
//   _sop, _nor  -> active-HIGH outputs y[i]   (y[i]=1 when a == i)
//   _pos, _nand -> active-LOW  outputs y_n[i] (y_n[i]=0 when a == i)

module decoder2to4_sop (input [1:0] a, output [3:0] y);
    wire na1, na0;
    not g_n1 (na1, a[1]);
    not g_n0 (na0, a[0]);
    and g0 (y[0], na1, na0);
    and g1 (y[1], na1, a[0]);
    and g2 (y[2], a[1], na0);
    and g3 (y[3], a[1], a[0]);
endmodule

module decoder2to4_nor (input [1:0] a, output [3:0] y);
    wire na1, na0;
    not g_n1 (na1, a[1]);
    not g_n0 (na0, a[0]);
    nor g0 (y[0], a[1],  a[0]);
    nor g1 (y[1], a[1],  na0);
    nor g2 (y[2], na1,   a[0]);
    nor g3 (y[3], na1,   na0);
endmodule

module decoder2to4_pos (input [1:0] a, output [3:0] y_n);
    wire na1, na0;
    not g_n1 (na1, a[1]);
    not g_n0 (na0, a[0]);
    or g0 (y_n[0], a[1], a[0]);
    or g1 (y_n[1], a[1], na0);
    or g2 (y_n[2], na1,  a[0]);
    or g3 (y_n[3], na1,  na0);
endmodule

module decoder2to4_nand (input [1:0] a, output [3:0] y_n);
    wire na1, na0;
    not g_n1 (na1, a[1]);
    not g_n0 (na0, a[0]);
    nand g0 (y_n[0], na1,  na0);
    nand g1 (y_n[1], na1,  a[0]);
    nand g2 (y_n[2], a[1], na0);
    nand g3 (y_n[3], a[1], a[0]);
endmodule
