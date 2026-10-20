// Parameterized combinational ALU (behavioral/dataflow style).
//
// Flag semantics (all flags are recomputed from the current inputs; nothing
// is held over from a previous operation):
//   carry    : ADD only - carry out of the MSB (unsigned overflow). 0 otherwise.
//   borrow   : SUB only - 1 when a < b (unsigned). 0 otherwise.
//   overflow : ADD/SUB only - signed two's-complement overflow. 0 otherwise.
//   zero     : 1 when y == 0, for EVERY opcode.
//   negative : y[WIDTH-1], for EVERY opcode (sign bit of the result; it is
//              only a "negative number" for signed arithmetic/logic data).
`include "alu_opcodes.vh"

module alu #(
    parameter WIDTH = 8
) (
    input      [WIDTH-1:0] a,
    input      [WIDTH-1:0] b,
    input      [2:0]       op,
    output reg [WIDTH-1:0] y,
    output reg             carry,
    output reg             borrow,
    output reg             overflow,
    output                 zero,
    output                 negative
);
    reg [WIDTH:0] wide;     // WIDTH+1 bits: keeps the carry/borrow bit

    always @* begin
        wide     = {(WIDTH+1){1'b0}};
        y        = {WIDTH{1'b0}};
        carry    = 1'b0;
        borrow   = 1'b0;
        overflow = 1'b0;
        case (op)
            `ALU_OP_ADD: begin
                wide     = {1'b0, a} + {1'b0, b};
                y        = wide[WIDTH-1:0];
                carry    = wide[WIDTH];
                overflow = (a[WIDTH-1] == b[WIDTH-1]) && (y[WIDTH-1] != a[WIDTH-1]);
            end
            `ALU_OP_SUB: begin
                wide     = {1'b0, a} - {1'b0, b};
                y        = wide[WIDTH-1:0];
                borrow   = wide[WIDTH];     // wraps negative exactly when a < b
                overflow = (a[WIDTH-1] != b[WIDTH-1]) && (y[WIDTH-1] != a[WIDTH-1]);
            end
            `ALU_OP_AND:   y = a & b;
            `ALU_OP_OR:    y = a | b;
            `ALU_OP_XOR:   y = a ^ b;
            `ALU_OP_XNOR:  y = ~(a ^ b);
            `ALU_OP_NOTA:  y = ~a;
            `ALU_OP_PASSB: y = b;
            default:       y = {WIDTH{1'b0}};
        endcase
    end

    assign zero     = (y == {WIDTH{1'b0}});
    assign negative = y[WIDTH-1];
endmodule

// Fixed-width wrappers (same ports/opcodes at every width).
module alu_1bit (input a, input b, input [2:0] op,
                 output y, output carry, output borrow, output overflow,
                 output zero, output negative);
    alu #(.WIDTH(1)) core (.a(a), .b(b), .op(op), .y(y), .carry(carry),
        .borrow(borrow), .overflow(overflow), .zero(zero), .negative(negative));
endmodule

module alu_4bit (input [3:0] a, input [3:0] b, input [2:0] op,
                 output [3:0] y, output carry, output borrow, output overflow,
                 output zero, output negative);
    alu #(.WIDTH(4)) core (.a(a), .b(b), .op(op), .y(y), .carry(carry),
        .borrow(borrow), .overflow(overflow), .zero(zero), .negative(negative));
endmodule

module alu_8bit (input [7:0] a, input [7:0] b, input [2:0] op,
                 output [7:0] y, output carry, output borrow, output overflow,
                 output zero, output negative);
    alu #(.WIDTH(8)) core (.a(a), .b(b), .op(op), .y(y), .carry(carry),
        .borrow(borrow), .overflow(overflow), .zero(zero), .negative(negative));
endmodule
