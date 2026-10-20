// Carry-lookahead adders.
//   g[i] = a[i] & b[i]          (generate)
//   p[i] = a[i] ^ b[i]          (propagate)
//   c[i+1] = g[i] | p[i] & c[i], expanded so every carry depends only on
//   g, p and cin (not on the previous carry):
//   c1 = g0 | p0 c0
//   c2 = g1 | p1 g0 | p1 p0 c0
//   c3 = g2 | p2 g1 | p2 p1 g0 | p2 p1 p0 c0
//   c4 = g3 | p3 g2 | p3 p2 g1 | p3 p2 p1 g0 | p3 p2 p1 p0 c0
//   sum[i] = p[i] ^ c[i]
// group_p / group_g let several 4-bit blocks be chained by a second
// lookahead level (see cla_adder16).

module cla_adder4 (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout,
    output       group_p,
    output       group_g
);
    wire [3:0] g = a & b;
    wire [3:0] p = a ^ b;
    wire c1 = g[0] | (p[0] & cin);
    wire c2 = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
    wire c3 = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & cin);
    assign group_p = &p;
    assign group_g = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);
    assign cout    = group_g | (group_p & cin);
    assign sum     = p ^ {c3, c2, c1, cin};
endmodule

module cla_adder4_bh (
    input      [3:0] a,
    input      [3:0] b,
    input            cin,
    output reg [3:0] sum,
    output reg       cout
);
    always @* begin
        {cout, sum} = {1'b0, a} + {1'b0, b} + {4'b0000, cin};
    end
endmodule

// 16-bit adder: four cla_adder4 blocks + a second-level lookahead unit that
// computes the block carries c4, c8, c12, c16 from group P/G.
module cla_adder16 (
    input  [15:0] a,
    input  [15:0] b,
    input         cin,
    output [15:0] sum,
    output        cout
);
    wire [3:0] gp, gg;
    wire c4  = gg[0] | (gp[0] & cin);
    wire c8  = gg[1] | (gp[1] & gg[0]) | (gp[1] & gp[0] & cin);
    wire c12 = gg[2] | (gp[2] & gg[1]) | (gp[2] & gp[1] & gg[0]) | (gp[2] & gp[1] & gp[0] & cin);
    assign cout = gg[3] | (gp[3] & gg[2]) | (gp[3] & gp[2] & gg[1]) |
                  (gp[3] & gp[2] & gp[1] & gg[0]) | (gp[3] & gp[2] & gp[1] & gp[0] & cin);
    wire [3:0] unused_cout;
    cla_adder4 blk0 (.a(a[3:0]),   .b(b[3:0]),   .cin(cin), .sum(sum[3:0]),   .cout(unused_cout[0]), .group_p(gp[0]), .group_g(gg[0]));
    cla_adder4 blk1 (.a(a[7:4]),   .b(b[7:4]),   .cin(c4),  .sum(sum[7:4]),   .cout(unused_cout[1]), .group_p(gp[1]), .group_g(gg[1]));
    cla_adder4 blk2 (.a(a[11:8]),  .b(b[11:8]),  .cin(c8),  .sum(sum[11:8]),  .cout(unused_cout[2]), .group_p(gp[2]), .group_g(gg[2]));
    cla_adder4 blk3 (.a(a[15:12]), .b(b[15:12]), .cin(c12), .sum(sum[15:12]), .cout(unused_cout[3]), .group_p(gp[3]), .group_g(gg[3]));
endmodule
