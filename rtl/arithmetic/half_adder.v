// Half adder: SUM = A xor B, CARRY = A and B.
// Naming convention: the plain module name is the structural (gate-level)
// form; _df is dataflow (assign), _bh is behavioral (always block).

module half_adder (
    input  a,
    input  b,
    output sum,
    output carry
);
    xor g_sum   (sum,   a, b);
    and g_carry (carry, a, b);
endmodule

module half_adder_df (
    input  a,
    input  b,
    output sum,
    output carry
);
    assign sum   = a ^ b;
    assign carry = a & b;
endmodule

module half_adder_bh (
    input      a,
    input      b,
    output reg sum,
    output reg carry
);
    // Arithmetic view: widen to 2 bits so the carry is not truncated.
    always @* begin
        {carry, sum} = {1'b0, a} + {1'b0, b};
    end
endmodule
