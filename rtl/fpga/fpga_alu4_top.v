// Board-agnostic FPGA top levels. Port names are generic (sw / led); the
// mapping to physical pins is board specific and intentionally NOT provided
// here - see docs/fpga/ and fpga/pin_assignments.template.csv.
// Polarity assumption: switches and LEDs are treated as active-high. Check
// your board's schematic - some boards drive LEDs or buttons active-low.

// 4-bit ALU demo (operands limited to 3 switches each so everything fits on
// a 10-switch / 10-LED board):
//   a = {1'b0, sw[2:0]}, b = {1'b0, sw[5:3]}, op = sw[8:6]
//   led[3:0] = result, led[4]=carry, led[5]=borrow, led[6]=overflow,
//   led[7]=zero, led[8]=negative
module fpga_alu4_top (
    input  [8:0] sw,
    output [8:0] led
);
    alu_4bit u_alu (
        .a({1'b0, sw[2:0]}), .b({1'b0, sw[5:3]}), .op(sw[8:6]),
        .y(led[3:0]), .carry(led[4]), .borrow(led[5]), .overflow(led[6]),
        .zero(led[7]), .negative(led[8]));
endmodule
