// Small datapath blocks: incrementer, decrementer, adder/subtractor,
// 1-bit comparator (3 styles) and 4-bit comparator built from 1-bit cells.

module incrementer #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] a,
    output [WIDTH-1:0] y,
    output             cout        // 1 when a is all ones (wraps to 0)
);
    assign {cout, y} = {1'b0, a} + {{WIDTH{1'b0}}, 1'b1};
endmodule

module decrementer #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] a,
    output [WIDTH-1:0] y,
    output             borrow      // 1 when a is zero (wraps to all ones)
);
    assign {borrow, y} = {1'b0, a} - {{WIDTH{1'b0}}, 1'b1};
endmodule

// sub=0: y = a + b ; sub=1: y = a - b  (a + ~b + 1).
// cout is the raw adder carry (for sub, cout=1 means NO borrow).
// overflow is the signed two's-complement overflow flag.
module adder_subtractor #(parameter WIDTH = 4) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              sub,
    output [WIDTH-1:0] y,
    output             cout,
    output             overflow
);
    wire [WIDTH-1:0] bx = b ^ {WIDTH{sub}};
    ripple_adder_n #(.WIDTH(WIDTH)) add (.a(a), .b(bx), .cin(sub), .sum(y), .cout(cout));
    assign overflow = (a[WIDTH-1] == bx[WIDTH-1]) && (y[WIDTH-1] != a[WIDTH-1]);
endmodule

// ------------------------------------------------------ 1-bit comparator
module comparator1 (input a, input b, output gt, output eq, output lt);
    wire na, nb;
    not g_na (na, a);
    not g_nb (nb, b);
    and g_gt (gt, a, nb);
    and g_lt (lt, na, b);
    xnor g_eq (eq, a, b);
endmodule

module comparator1_df (input a, input b, output gt, output eq, output lt);
    assign gt = a & ~b;
    assign lt = ~a & b;
    assign eq = ~(a ^ b);
endmodule

module comparator1_bh (input a, input b, output reg gt, output reg eq, output reg lt);
    always @* begin
        gt = 1'b0; eq = 1'b0; lt = 1'b0;
        if (a > b)       gt = 1'b1;
        else if (a == b) eq = 1'b1;
        else             lt = 1'b1;
    end
endmodule

// ------------------------------------------------------ 4-bit comparator
// Structural: four comparator1 cells, MSB-first cascade.
//   gt = g3 | e3 g2 | e3 e2 g1 | e3 e2 e1 g0      eq = e3 e2 e1 e0
//   lt = l3 | e3 l2 | e3 e2 l1 | e3 e2 e1 l0
module comparator4 (input [3:0] a, input [3:0] b, output gt, output eq, output lt);
    wire [3:0] g, e, l;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : bitcmp
            comparator1 c (.a(a[i]), .b(b[i]), .gt(g[i]), .eq(e[i]), .lt(l[i]));
        end
    endgenerate
    assign gt = g[3] | (e[3] & g[2]) | (e[3] & e[2] & g[1]) | (e[3] & e[2] & e[1] & g[0]);
    assign lt = l[3] | (e[3] & l[2]) | (e[3] & e[2] & l[1]) | (e[3] & e[2] & e[1] & l[0]);
    assign eq = &e;
endmodule

module comparator4_df (input [3:0] a, input [3:0] b, output gt, output eq, output lt);
    assign gt = (a > b);
    assign eq = (a == b);
    assign lt = (a < b);
endmodule
