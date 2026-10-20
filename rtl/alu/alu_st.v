// Structural ALU: WIDTH identical bit slices (full adder + logic unit + 8:1
// result MUX selected by `op`). Same ports, opcodes and flag semantics as
// alu.v (see that file). The carry chain is a ripple chain of full adders;
// SUB feeds b inverted with carry-in 1 (a + ~b + 1).
`include "alu_opcodes.vh"

module alu_slice (
    input        a,
    input        b,
    input        cin,
    input  [2:0] op,
    output       y,
    output       cout
);
    wire is_sub = (op == `ALU_OP_SUB);
    wire bx     = b ^ is_sub;
    wire s;
    full_adder fa (.a(a), .b(bx), .cin(cin), .sum(s), .cout(cout));
    // d[i] is the result for opcode i
    mux8 sel (.d({b, ~a, ~(a ^ b), a ^ b, a | b, a & b, s, s}), .s(op), .y(y));
endmodule

module alu_st #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input  [2:0]       op,
    output [WIDTH-1:0] y,
    output             carry,
    output             borrow,
    output             overflow,
    output             zero,
    output             negative
);
    wire is_add = (op == `ALU_OP_ADD);
    wire is_sub = (op == `ALU_OP_SUB);
    wire [WIDTH:0] c;
    assign c[0] = is_sub;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : slice
            alu_slice s (.a(a[i]), .b(b[i]), .cin(c[i]), .op(op), .y(y[i]), .cout(c[i+1]));
        end
    endgenerate
    assign carry    = is_add & c[WIDTH];
    assign borrow   = is_sub & ~c[WIDTH];
    assign overflow = (is_add | is_sub) & (c[WIDTH] ^ c[WIDTH-1]);
    assign zero     = ~|y;
    assign negative = y[WIDTH-1];
endmodule
