// Exhaustive test of all 4-bit adders (all a, b, cin = 512 vectors per DUT)
// and of the n-bit parameterized adder at n=8 (131072 vectors).
`timescale 1ns/1ps
module tb_ripple_adder;
    reg [3:0] a, b;
    reg       cin;
    reg [7:0] a8, b8;
    reg       cin8;
    integer errors, tests, i, j, k;
    integer expv;
    reg [8*256-1:0] vcdfile;

    wire [3:0] s [0:5];
    wire [5:0] co;
    ripple_adder4_bh    u0 (.a(a), .b(b), .cin(cin), .sum(s[0]), .cout(co[0]));
    ripple_adder4_df    u1 (.a(a), .b(b), .cin(cin), .sum(s[1]), .cout(co[1]));
    ripple_adder4       u2 (.a(a), .b(b), .cin(cin), .sum(s[2]), .cout(co[2]));
    ripple_adder4_gates u3 (.a(a), .b(b), .cin(cin), .sum(s[3]), .cout(co[3]));
    ripple_adder4_nand  u4 (.a(a), .b(b), .cin(cin), .sum(s[4]), .cout(co[4]));
    ripple_adder4_nor   u5 (.a(a), .b(b), .cin(cin), .sum(s[5]), .cout(co[5]));

    wire [7:0] s8;
    wire       co8;
    ripple_adder_n #(.WIDTH(8)) u8 (.a(a8), .b(b8), .cin(cin8), .sum(s8), .cout(co8));

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_ripple_adder);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a = i; b = j; cin = k; #1;
                    expv = i + j + k;                 // 0..31
                    begin : cmp4
                        integer d;
                        for (d = 0; d < 6; d = d + 1) begin
                            tests = tests + 1;
                            if ({co[d], s[d]} !== expv[4:0]) begin
                                errors = errors + 1;
                                $display("FAIL dut%0d a=%0d b=%0d cin=%0d got=%0d expected=%0d",
                                         d, i, j, k, {co[d], s[d]}, expv);
                            end
                        end
                    end
                end
        // n-bit adder, WIDTH=8, exhaustive
        for (i = 0; i < 256; i = i + 1)
            for (j = 0; j < 256; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a8 = i; b8 = j; cin8 = k; #1;
                    expv = i + j + k;
                    tests = tests + 1;
                    if ({co8, s8} !== expv[8:0]) begin
                        errors = errors + 1;
                        $display("FAIL n=8 a=%0d b=%0d cin=%0d got=%0d expected=%0d",
                                 i, j, k, {co8, s8}, expv);
                    end
                end
        // documented synthetic example: 13 + 7 = 20 -> sum=4, cout=1
        a = 4'd13; b = 4'd7; cin = 1'b0; #1;
        tests = tests + 1;
        if ({co[2], s[2]} !== 5'd20) begin errors = errors + 1; $display("FAIL example 13+7"); end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
