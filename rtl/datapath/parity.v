// Parity generator and checker for WIDTH data bits.
//   even_p : bit that makes the total number of 1s (data + parity) EVEN
//   odd_p  : bit that makes the total number of 1s ODD (= ~even_p)
// parity_checker_even: error = 1 when {data, parity} has an ODD number of 1s.

module parity_generator #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] data,
    output             even_p,
    output             odd_p
);
    assign even_p = ^data;
    assign odd_p  = ~(^data);
endmodule

module parity_checker_even #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] data,
    input              parity,
    output             error
);
    assign error = ^{data, parity};
endmodule
