// 4-bit and n-bit ripple-borrow subtractors built from full_subtractor stages.
// Computes a - b - bin. borrow b[i] is the borrow INTO bit i; b[WIDTH] is the
// borrow OUT of the MSB: bout = 1 exactly when a < b + bin (unsigned).

module ripple_subtractor4 (
    input  [3:0] a,
    input  [3:0] b,
    input        bin,
    output [3:0] diff,
    output       bout
);
    wire [4:0] br;
    assign br[0] = bin;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage
            full_subtractor fs (.a(a[i]), .b(b[i]), .bin(br[i]), .diff(diff[i]), .bout(br[i+1]));
        end
    endgenerate
    assign bout = br[4];
endmodule

module ripple_subtractor_n #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              bin,
    output [WIDTH-1:0] diff,
    output             bout
);
    wire [WIDTH:0] br;
    assign br[0] = bin;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage
            full_subtractor fs (.a(a[i]), .b(b[i]), .bin(br[i]), .diff(diff[i]), .bout(br[i+1]));
        end
    endgenerate
    assign bout = br[WIDTH];
endmodule
