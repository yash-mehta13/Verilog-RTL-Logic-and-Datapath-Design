// Half/full adders and subtractors using ONLY two-input NAND or NOR gates.
// An inverter is a NAND/NOR with both inputs tied together and is counted as
// one gate. Gate counts are derived by tools/verification/gate_count.py by
// parsing the instances below - keep one primitive per line.

// ---------------------------------------------------------------- NAND
module half_adder_nand (input a, input b, output sum, output carry);
    wire n1, n2, n3;
    nand g1 (n1, a, b);
    nand g2 (n2, a, n1);
    nand g3 (n3, b, n1);
    nand g4 (sum, n2, n3);
    nand g5 (carry, n1, n1);      // inverter: carry = a.b
endmodule

module half_subtractor_nand (input a, input b, output diff, output borrow);
    wire n1, n2, n3;
    nand g1 (n1, a, b);
    nand g2 (n2, a, n1);
    nand g3 (n3, b, n1);
    nand g4 (diff, n2, n3);
    nand g5 (borrow, n3, n3);     // inverter: borrow = ~a.b
endmodule

module full_adder_nand (input a, input b, input cin, output sum, output cout);
    wire n1, n2, n3, x, n5, n6, n7;
    nand g1 (n1, a, b);
    nand g2 (n2, a, n1);
    nand g3 (n3, b, n1);
    nand g4 (x, n2, n3);          // x = a ^ b
    nand g5 (n5, x, cin);
    nand g6 (n6, x, n5);
    nand g7 (n7, cin, n5);
    nand g8 (sum, n6, n7);
    nand g9 (cout, n1, n5);       // cout = a.b + (a^b).cin
endmodule

module full_subtractor_nand (input a, input b, input bin, output diff, output bout);
    wire n1, n2, n3, x, n5, n6, n7;
    nand g1 (n1, a, b);
    nand g2 (n2, a, n1);
    nand g3 (n3, b, n1);          // ~n3 = ~a.b
    nand g4 (x, n2, n3);          // x = a ^ b
    nand g5 (n5, x, bin);
    nand g6 (n6, x, n5);
    nand g7 (n7, bin, n5);        // ~n7 = ~x.bin
    nand g8 (diff, n6, n7);
    nand g9 (bout, n3, n7);       // bout = ~a.b + ~x.bin
endmodule

// ----------------------------------------------------------------- NOR
module half_adder_nor (input a, input b, output sum, output carry);
    wire n1, n2, n3, xn;
    nor g1 (n1, a, b);
    nor g2 (n2, a, n1);           // ~a.b
    nor g3 (n3, b, n1);           // a.~b
    nor g4 (xn, n2, n3);          // xnor
    nor g5 (sum, xn, xn);         // inverter: xor
    nor g6 (carry, n1, sum);      // (a+b).~(a^b) = a.b
endmodule

module half_subtractor_nor (input a, input b, output diff, output borrow);
    wire n1, n2, n3, xn;
    nor g1 (n1, a, b);
    nor g2 (n2, a, n1);           // ~a.b  (this net IS the borrow)
    nor g3 (n3, b, n1);
    nor g4 (xn, n2, n3);
    nor g5 (diff, xn, xn);        // inverter
    assign borrow = n2;           // wire alias, no gate
endmodule

module full_adder_nor (input a, input b, input cin, output sum, output cout);
    wire n1, n2, n3, xn, m1, m2, m3;
    nor g1 (n1, a, b);
    nor g2 (n2, a, n1);
    nor g3 (n3, b, n1);
    nor g4 (xn, n2, n3);          // xn = xnor(a,b)
    nor g5 (m1, xn, cin);
    nor g6 (m2, xn, m1);
    nor g7 (m3, cin, m1);
    nor g8 (sum, m2, m3);         // xnor(xn, cin) = a^b^cin
    nor g9 (cout, n1, m1);        // (a+b).(xn+cin)
endmodule

module full_subtractor_nor (input a, input b, input bin, output diff, output bout);
    wire n1, n2, n3, xn, x, m1, m2, m3, sn;
    nor g1  (n1, a, b);
    nor g2  (n2, a, n1);
    nor g3  (n3, b, n1);          // ~n3 = ~a + b
    nor g4  (xn, n2, n3);
    nor g5  (x, xn, xn);          // inverter: x = a ^ b
    nor g6  (m1, x, bin);
    nor g7  (m2, x, m1);
    nor g8  (m3, bin, m1);
    nor g9  (sn, m2, m3);         // xnor(x, bin)
    nor g10 (diff, sn, sn);       // inverter: a ^ b ^ bin
    nor g11 (bout, n3, m1);       // (~a+b).(x+bin)
endmodule

// -------------------------------------------- 4-bit adders from the above
module ripple_adder4_nand (input [3:0] a, input [3:0] b, input cin,
                           output [3:0] sum, output cout);
    wire [4:0] c;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage
            full_adder_nand fa (.a(a[i]), .b(b[i]), .cin(c[i]), .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[4];
endmodule

module ripple_adder4_nor (input [3:0] a, input [3:0] b, input cin,
                          output [3:0] sum, output cout);
    wire [4:0] c;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : stage
            full_adder_nor fa (.a(a[i]), .b(b[i]), .cin(c[i]), .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[4];
endmodule
