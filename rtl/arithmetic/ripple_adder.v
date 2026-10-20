// Ripple-carry adders. carry c[i] is the carry INTO bit i; c[WIDTH] is COUT.

// 4-bit adder built from four reusable full_adder stages.
module ripple_adder4 (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [4:0] c;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]), .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[4];
endmodule

// 4-bit adder from basic gates only (2 xor + 2 and + 1 or per bit = 20 gates).
module ripple_adder4_gates (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [4:0] c;
    wire [3:0] p, g, pc;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage
            xor x_p  (p[i],   a[i], b[i]);
            xor x_s  (sum[i], p[i], c[i]);
            and a_g  (g[i],   a[i], b[i]);
            and a_pc (pc[i],  p[i], c[i]);
            or  o_c  (c[i+1], g[i], pc[i]);
        end
    endgenerate
    assign cout = c[4];
endmodule

module ripple_adder4_df (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    assign {cout, sum} = {1'b0, a} + {1'b0, b} + {4'b0000, cin};
endmodule

module ripple_adder4_bh (
    input      [3:0] a,
    input      [3:0] b,
    input            cin,
    output reg [3:0] sum,
    output reg       cout
);
    always @* begin
        {cout, sum} = {1'b0, a} + {1'b0, b} + {4'b0000, cin};
    end
endmodule

// Parameterized n-bit parallel adder (structural, generate loop).
module ripple_adder_n #(
    parameter WIDTH = 8
) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    input              cin,
    output [WIDTH-1:0] sum,
    output             cout
);
    wire [WIDTH:0] c;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : stage
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]), .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[WIDTH];
endmodule
