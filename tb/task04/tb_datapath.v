// Comparators (1-bit x3 styles, 4-bit x2), incrementer, decrementer and
// adder/subtractor: exhaustive at 4 bits.
`timescale 1ns/1ps
module tb_datapath;
    reg [3:0] a, b;
    reg       sub;
    integer errors, tests, i, j, k;
    reg [8*256-1:0] vcdfile;

    wire [2:0] g1, e1, l1;
    comparator1    c1a (.a(a[0]), .b(b[0]), .gt(g1[0]), .eq(e1[0]), .lt(l1[0]));
    comparator1_df c1b (.a(a[0]), .b(b[0]), .gt(g1[1]), .eq(e1[1]), .lt(l1[1]));
    comparator1_bh c1c (.a(a[0]), .b(b[0]), .gt(g1[2]), .eq(e1[2]), .lt(l1[2]));
    wire [1:0] g4, e4, l4;
    comparator4    c4a (.a(a), .b(b), .gt(g4[0]), .eq(e4[0]), .lt(l4[0]));
    comparator4_df c4b (.a(a), .b(b), .gt(g4[1]), .eq(e4[1]), .lt(l4[1]));

    wire [3:0] inc_y, dec_y, as_y;
    wire inc_c, dec_b, as_c, as_v;
    incrementer #(.WIDTH(4)) ui (.a(a), .y(inc_y), .cout(inc_c));
    decrementer #(.WIDTH(4)) ud (.a(a), .y(dec_y), .borrow(dec_b));
    adder_subtractor #(.WIDTH(4)) ua (.a(a), .b(b), .sub(sub), .y(as_y), .cout(as_c), .overflow(as_v));

    task chk;
        input integer got;
        input integer expd;
        input [8*16-1:0] name;
        begin
            tests = tests + 1;
            if (got !== expd) begin
                errors = errors + 1;
                $display("FAIL %0s a=%0d b=%0d sub=%b got=%0d expected=%0d", name, a, b, sub, got, expd);
            end
        end
    endtask

    integer sa, sb, sres;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_datapath);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a = i; b = j; sub = k; #1;
                    if (k == 0) begin
                        // 1-bit comparators see only bit 0
                        chk(g1[0], (a[0] > b[0]), "cmp1.gt"); chk(g1[1], (a[0] > b[0]), "cmp1_df.gt"); chk(g1[2], (a[0] > b[0]), "cmp1_bh.gt");
                        chk(e1[0], (a[0] == b[0]), "cmp1.eq"); chk(e1[1], (a[0] == b[0]), "cmp1_df.eq"); chk(e1[2], (a[0] == b[0]), "cmp1_bh.eq");
                        chk(l1[0], (a[0] < b[0]), "cmp1.lt"); chk(l1[1], (a[0] < b[0]), "cmp1_df.lt"); chk(l1[2], (a[0] < b[0]), "cmp1_bh.lt");
                        chk(g4[0], (i > j), "cmp4.gt"); chk(g4[1], (i > j), "cmp4_df.gt");
                        chk(e4[0], (i == j), "cmp4.eq"); chk(e4[1], (i == j), "cmp4_df.eq");
                        chk(l4[0], (i < j), "cmp4.lt"); chk(l4[1], (i < j), "cmp4_df.lt");
                        chk(g4[0] + e4[0] + l4[0], 1, "cmp4 one-hot");
                        chk(inc_y, (i + 1) % 16, "incrementer");
                        chk(inc_c, (i == 15), "incr.cout");
                        chk(dec_y, (i + 15) % 16, "decrementer");
                        chk(dec_b, (i == 0), "decr.borrow");
                    end
                    sa = (i >= 8) ? i - 16 : i;
                    sb = (j >= 8) ? j - 16 : j;
                    if (k == 0) begin
                        chk(as_y, (i + j) % 16, "addsub.add");
                        chk(as_c, ((i + j) >= 16), "addsub.cout");
                        sres = sa + sb;
                    end else begin
                        chk(as_y, (((i - j) % 16) + 16) % 16, "addsub.sub");
                        chk(as_c, (i >= j), "addsub.cout");   // 1 = no borrow
                        sres = sa - sb;
                    end
                    chk(as_v, (sres < -8) || (sres > 7), "addsub.ovf");
                end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
