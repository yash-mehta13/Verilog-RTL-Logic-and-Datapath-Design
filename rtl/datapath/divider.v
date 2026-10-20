// Combinational restoring divider (unsigned): quotient = dividend / divisor,
// remainder = dividend % divisor. One compare/subtract row per quotient bit,
// MSB first (long division in binary). Purely combinational - for an FPGA a
// sequential version would be preferred; this one is instructional.
//
// Division by zero: div_by_zero = 1, quotient = all ones, remainder = dividend
// (the restoring algorithm's natural result; callers must check the flag).
module divider_restoring #(
    parameter WIDTH = 8
) (
    input      [WIDTH-1:0] dividend,
    input      [WIDTH-1:0] divisor,
    output reg [WIDTH-1:0] quotient,
    output reg [WIDTH-1:0] remainder,
    output                 div_by_zero
);
    integer     i;
    reg [WIDTH:0]   rem;        // partial remainder, one bit wider than the divisor
    reg [WIDTH-1:0] q;

    always @* begin
        rem = {(WIDTH+1){1'b0}};
        q   = {WIDTH{1'b0}};
        for (i = WIDTH - 1; i >= 0; i = i - 1) begin
            rem = {rem[WIDTH-1:0], dividend[i]};          // bring down next bit
            if (rem >= {1'b0, divisor}) begin
                rem  = rem - {1'b0, divisor};              // subtract; quotient bit = 1
                q[i] = 1'b1;
            end                                            // else restore: keep rem, bit = 0
        end
        quotient  = q;
        remainder = rem[WIDTH-1:0];
    end

    assign div_by_zero = (divisor == {WIDTH{1'b0}});
endmodule
