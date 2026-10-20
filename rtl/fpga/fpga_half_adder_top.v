// Board-agnostic FPGA top levels. Port names are generic (sw / led); the
// mapping to physical pins is board specific and intentionally NOT provided
// here - see docs/fpga/ and fpga/pin_assignments.template.csv.
// Polarity assumption: switches and LEDs are treated as active-high. Check
// your board's schematic - some boards drive LEDs or buttons active-low.

// Half adder demo: sw[0]=A, sw[1]=B, led[0]=SUM, led[1]=CARRY
module fpga_half_adder_top (
    input  [1:0] sw,
    output [1:0] led
);
    half_adder ha (.a(sw[0]), .b(sw[1]), .sum(led[0]), .carry(led[1]));
endmodule
