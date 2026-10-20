// Full subtractor computes A - B - BIN (BIN = borrow-in, BOUT = borrow-out).
//   DIFF = A ^ B ^ BIN
//   BOUT = (~A & B) | (~(A ^ B) & BIN)
// Structural form = two half subtractors + one OR gate.

module full_subtractor (
    input  a,
    input  b,
    input  bin,
    output diff,
    output bout
);
    wire d1, b1, b2;
    half_subtractor hs0 (.a(a),  .b(b),   .diff(d1),   .borrow(b1));
    half_subtractor hs1 (.a(d1), .b(bin), .diff(diff), .borrow(b2));
    or g_bout (bout, b1, b2);
endmodule

module full_subtractor_df (
    input  a,
    input  b,
    input  bin,
    output diff,
    output bout
);
    assign diff = a ^ b ^ bin;
    assign bout = (~a & b) | (~(a ^ b) & bin);
endmodule

module full_subtractor_bh (
    input      a,
    input      b,
    input      bin,
    output reg diff,
    output reg bout
);
    always @* begin
        {bout, diff} = {1'b0, a} - {1'b0, b} - {1'b0, bin};
    end
endmodule
