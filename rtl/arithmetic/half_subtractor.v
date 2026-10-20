// Half subtractor computes A - B: DIFF = A xor B, BORROW = (not A) and B.

module half_subtractor (
    input  a,
    input  b,
    output diff,
    output borrow
);
    wire na;
    xor g_diff   (diff, a, b);
    not g_na     (na, a);
    and g_borrow (borrow, na, b);
endmodule

module half_subtractor_df (
    input  a,
    input  b,
    output diff,
    output borrow
);
    assign diff   = a ^ b;
    assign borrow = ~a & b;
endmodule

module half_subtractor_bh (
    input      a,
    input      b,
    output reg diff,
    output reg borrow
);
    // 2-bit modular difference: bit 1 is set exactly when A < B.
    always @* begin
        {borrow, diff} = {1'b0, a} - {1'b0, b};
    end
endmodule
