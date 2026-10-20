// Exhaustive test of the 4-bit ripple subtractor (all a, b, bin) and of the
// n-bit subtractor at WIDTH=8 against integer arithmetic.
`timescale 1ns/1ps
module tb_ripple_subtractor;
    reg  [3:0] a, b;
    reg        bin;
    reg  [7:0] a8, b8;
    reg        bin8;
    wire [3:0] d4;
    wire       bo4;
    wire [7:0] d8;
    wire       bo8;
    integer errors, tests, i, j, k, v, ed;
    reg [8*256-1:0] vcdfile;
    ripple_subtractor4 u4 (.a(a), .b(b), .bin(bin), .diff(d4), .bout(bo4));
    ripple_subtractor_n #(.WIDTH(8)) u8 (.a(a8), .b(b8), .bin(bin8), .diff(d8), .bout(bo8));
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_ripple_subtractor);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a = i; b = j; bin = k; #1;
                    v = i - j - k;
                    ed = (v + 32) % 16;
                    tests = tests + 1;
                    if (d4 !== ed[3:0] || bo4 !== (v < 0)) begin
                        errors = errors + 1;
                        $display("FAIL 4-bit %0d-%0d-%0d got diff=%0d bout=%b", i, j, k, d4, bo4);
                    end
                end
        for (i = 0; i < 256; i = i + 1)
            for (j = 0; j < 256; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a8 = i; b8 = j; bin8 = k; #1;
                    v = i - j - k;
                    ed = (v + 512) % 256;
                    tests = tests + 1;
                    if (d8 !== ed[7:0] || bo8 !== (v < 0)) begin
                        errors = errors + 1;
                        $display("FAIL 8-bit %0d-%0d-%0d got diff=%0d bout=%b", i, j, k, d8, bo8);
                    end
                end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
