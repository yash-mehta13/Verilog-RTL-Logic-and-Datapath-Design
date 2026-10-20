// Exhaustive test of the 2x2, 3x3 and 4x4 unsigned multipliers (3 styles
// each) against integer multiplication, plus fixed corner-value checks that
// do not depend on the '*' operator.
`timescale 1ns/1ps
module tb_multipliers;
    reg [3:0] a, b;
    integer errors, tests, i, j;
    reg [8*256-1:0] vcdfile;

    wire [3:0] p2 [0:2];
    wire [5:0] p3 [0:2];
    wire [7:0] p4 [0:2];
    mult2x2    m2s (.a(a[1:0]), .b(b[1:0]), .p(p2[0]));
    mult2x2_df m2d (.a(a[1:0]), .b(b[1:0]), .p(p2[1]));
    mult2x2_bh m2b (.a(a[1:0]), .b(b[1:0]), .p(p2[2]));
    mult3x3    m3s (.a(a[2:0]), .b(b[2:0]), .p(p3[0]));
    mult3x3_df m3d (.a(a[2:0]), .b(b[2:0]), .p(p3[1]));
    mult3x3_bh m3b (.a(a[2:0]), .b(b[2:0]), .p(p3[2]));
    mult4x4    m4s (.a(a), .b(b), .p(p4[0]));
    mult4x4_df m4d (.a(a), .b(b), .p(p4[1]));
    mult4x4_bh m4b (.a(a), .b(b), .p(p4[2]));

    // reference by repeated addition (independent of '*')
    function integer ref_mul;
        input integer x;
        input integer y;
        integer n, acc;
        begin
            acc = 0;
            for (n = 0; n < y; n = n + 1) acc = acc + x;
            ref_mul = acc;
        end
    endfunction

    task expect;
        input integer got;
        input integer exp;
        input [8*16-1:0] name;
        begin
            tests = tests + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s a=%0d b=%0d got=%0d expected=%0d", name, a, b, got, exp);
            end
        end
    endtask

    integer d;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_multipliers);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                a = i; b = j; #1;
                for (d = 0; d < 3; d = d + 1) begin
                    if (i < 4 && j < 4) expect(p2[d], ref_mul(i, j), "mult2x2");
                    if (i < 8 && j < 8) expect(p3[d], ref_mul(i, j), "mult3x3");
                    expect(p4[d], ref_mul(i, j), "mult4x4");
                end
            end
        // corner values (explicit constants)
        a = 4'd3; b = 4'd3; #1; expect(p2[0], 9, "2x2 max");
        a = 4'd7; b = 4'd7; #1; expect(p3[0], 49, "3x3 max");
        a = 4'd15; b = 4'd15; #1; expect(p4[0], 225, "4x4 max");
        a = 4'd0; b = 4'd15; #1; expect(p4[0], 0, "4x4 zero");
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
