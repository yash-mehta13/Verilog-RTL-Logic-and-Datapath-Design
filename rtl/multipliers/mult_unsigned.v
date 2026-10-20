// Small UNSIGNED combinational multipliers (see booth_mult.v for signed).
// NxN unsigned product needs 2N bits: max (2^N-1)^2 = 2^(2N) - 2^(N+1) + 1.
//   plain = structural AND-array + half/full-adder rows
//   _df   = dataflow  (assign p = a * b)
//   _bh   = behavioral (always block)

// 2x2: 4 AND gates (partial products) + 2 half adders.
//   p0 = a0b0 ; (p1,c) = a1b0 + a0b1 ; (p2,p3) = a1b1 + c
module mult2x2 (input [1:0] a, input [1:0] b, output [3:0] p);
    wire a0b0, a1b0, a0b1, a1b1, c1;
    and g00 (a0b0, a[0], b[0]);
    and g10 (a1b0, a[1], b[0]);
    and g01 (a0b1, a[0], b[1]);
    and g11 (a1b1, a[1], b[1]);
    assign p[0] = a0b0;
    half_adder ha1 (.a(a1b0), .b(a0b1), .sum(p[1]), .carry(c1));
    half_adder ha2 (.a(a1b1), .b(c1),   .sum(p[2]), .carry(p[3]));
endmodule

module mult2x2_df (input [1:0] a, input [1:0] b, output [3:0] p);
    assign p = a * b;
endmodule

module mult2x2_bh (input [1:0] a, input [1:0] b, output reg [3:0] p);
    always @* p = a * b;
endmodule

// Generic NxN array multiplier: row i adds the partial product (a & {N{b[i]}})
// to the running sum with an N-bit ripple adder. t holds N+1 bit row results.
module mult_array_n #(parameter N = 4) (
    input  [N-1:0]   a,
    input  [N-1:0]   b,
    output [2*N-1:0] p
);
    wire [(N+1)*N-1:0] t;          // row i result at t[i*(N+1) +: N+1]
    wire [N*N-1:0]     pp;         // partial products, row i at pp[i*N +: N]
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : row
            assign pp[i*N +: N] = a & {N{b[i]}};
            if (i == 0) begin : first
                assign t[0 +: N+1] = {1'b0, pp[0 +: N]};
            end else begin : next
                wire [N-1:0] s;
                wire         co;
                ripple_adder_n #(.WIDTH(N)) add (
                    .a(t[(i-1)*(N+1)+1 +: N]), .b(pp[i*N +: N]), .cin(1'b0),
                    .sum(s), .cout(co));
                assign t[i*(N+1) +: N+1] = {co, s};
            end
            assign p[i] = t[i*(N+1)];
        end
    endgenerate
    assign p[2*N-1:N] = t[(N-1)*(N+1)+1 +: N];
endmodule

module mult3x3 (input [2:0] a, input [2:0] b, output [5:0] p);
    mult_array_n #(.N(3)) core (.a(a), .b(b), .p(p));
endmodule
module mult3x3_df (input [2:0] a, input [2:0] b, output [5:0] p);
    assign p = a * b;
endmodule
module mult3x3_bh (input [2:0] a, input [2:0] b, output reg [5:0] p);
    always @* p = a * b;
endmodule

module mult4x4 (input [3:0] a, input [3:0] b, output [7:0] p);
    mult_array_n #(.N(4)) core (.a(a), .b(b), .p(p));
endmodule
module mult4x4_df (input [3:0] a, input [3:0] b, output [7:0] p);
    assign p = a * b;
endmodule
module mult4x4_bh (input [3:0] a, input [3:0] b, output reg [7:0] p);
    always @* p = a * b;
endmodule
