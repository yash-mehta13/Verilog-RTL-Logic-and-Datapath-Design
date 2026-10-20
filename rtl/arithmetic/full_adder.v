// Full adder: SUM = A ^ B ^ CIN, COUT = A.B + CIN.(A ^ B).
// Structural form = two half adders + one OR gate.

module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    wire s1, c1, c2;
    half_adder ha0 (.a(a),  .b(b),   .sum(s1),  .carry(c1));
    half_adder ha1 (.a(s1), .b(cin), .sum(sum), .carry(c2));
    or g_cout (cout, c1, c2);
endmodule

module full_adder_df (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module full_adder_bh (
    input      a,
    input      b,
    input      cin,
    output reg sum,
    output reg cout
);
    always @* begin
        {cout, sum} = {1'b0, a} + {1'b0, b} + {1'b0, cin};
    end
endmodule
