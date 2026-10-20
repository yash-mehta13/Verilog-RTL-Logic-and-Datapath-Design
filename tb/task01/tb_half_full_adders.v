// Exhaustive self-checking test of half/full adders and subtractors in every
// implemented style. Expected values come from integer arithmetic, not from
// any of the modules under test.
`timescale 1ns/1ps
module tb_half_full_adders;
    reg a, b, cin;
    integer errors, tests;
    integer ia, ib, ic, v, exp0, exp1;
    reg [8*256-1:0] vcdfile;

    // half adder / subtractor: bh, df, st, nand, nor
    wire [4:0] ha_s, ha_c, hs_d, hs_b;
    half_adder_bh       u_ha0 (.a(a), .b(b), .sum(ha_s[0]), .carry(ha_c[0]));
    half_adder_df       u_ha1 (.a(a), .b(b), .sum(ha_s[1]), .carry(ha_c[1]));
    half_adder          u_ha2 (.a(a), .b(b), .sum(ha_s[2]), .carry(ha_c[2]));
    half_adder_nand     u_ha3 (.a(a), .b(b), .sum(ha_s[3]), .carry(ha_c[3]));
    half_adder_nor      u_ha4 (.a(a), .b(b), .sum(ha_s[4]), .carry(ha_c[4]));
    half_subtractor_bh   u_hs0 (.a(a), .b(b), .diff(hs_d[0]), .borrow(hs_b[0]));
    half_subtractor_df   u_hs1 (.a(a), .b(b), .diff(hs_d[1]), .borrow(hs_b[1]));
    half_subtractor      u_hs2 (.a(a), .b(b), .diff(hs_d[2]), .borrow(hs_b[2]));
    half_subtractor_nand u_hs3 (.a(a), .b(b), .diff(hs_d[3]), .borrow(hs_b[3]));
    half_subtractor_nor  u_hs4 (.a(a), .b(b), .diff(hs_d[4]), .borrow(hs_b[4]));

    // full adder / subtractor: bh, df, st, nand, nor, mux, decoder
    wire [6:0] fa_s, fa_c, fs_d, fs_b;
    full_adder_bh         u_fa0 (.a(a), .b(b), .cin(cin), .sum(fa_s[0]), .cout(fa_c[0]));
    full_adder_df         u_fa1 (.a(a), .b(b), .cin(cin), .sum(fa_s[1]), .cout(fa_c[1]));
    full_adder            u_fa2 (.a(a), .b(b), .cin(cin), .sum(fa_s[2]), .cout(fa_c[2]));
    full_adder_nand       u_fa3 (.a(a), .b(b), .cin(cin), .sum(fa_s[3]), .cout(fa_c[3]));
    full_adder_nor        u_fa4 (.a(a), .b(b), .cin(cin), .sum(fa_s[4]), .cout(fa_c[4]));
    full_adder_mux        u_fa5 (.a(a), .b(b), .cin(cin), .sum(fa_s[5]), .cout(fa_c[5]));
    full_adder_decoder    u_fa6 (.a(a), .b(b), .cin(cin), .sum(fa_s[6]), .cout(fa_c[6]));
    full_subtractor_bh      u_fs0 (.a(a), .b(b), .bin(cin), .diff(fs_d[0]), .bout(fs_b[0]));
    full_subtractor_df      u_fs1 (.a(a), .b(b), .bin(cin), .diff(fs_d[1]), .bout(fs_b[1]));
    full_subtractor         u_fs2 (.a(a), .b(b), .bin(cin), .diff(fs_d[2]), .bout(fs_b[2]));
    full_subtractor_nand    u_fs3 (.a(a), .b(b), .bin(cin), .diff(fs_d[3]), .bout(fs_b[3]));
    full_subtractor_nor     u_fs4 (.a(a), .b(b), .bin(cin), .diff(fs_d[4]), .bout(fs_b[4]));
    full_subtractor_mux     u_fs5 (.a(a), .b(b), .bin(cin), .diff(fs_d[5]), .bout(fs_b[5]));
    full_subtractor_decoder u_fs6 (.a(a), .b(b), .bin(cin), .diff(fs_d[6]), .bout(fs_b[6]));

    task check;
        input got;
        input expected;
        input [8*24-1:0] what;
        input integer idx;
        begin
            tests = tests + 1;
            if (got !== expected) begin
                errors = errors + 1;
                $display("FAIL %0s[%0d] a=%b b=%b cin=%b got=%b expected=%b",
                         what, idx, a, b, cin, got, expected);
            end
        end
    endtask

    integer k;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_half_full_adders);
        end
        errors = 0; tests = 0;
        for (v = 0; v < 8; v = v + 1) begin
            {a, b, cin} = v[2:0];
            ia = a; ib = b; ic = cin;
            #1;
            // addition: total = a+b(+cin); sum = total mod 2, carry = total / 2
            exp0 = (ia + ib) % 2;       exp1 = (ia + ib) / 2;
            for (k = 0; k < 5; k = k + 1) if (v[0] == 1'b0) begin
                check(ha_s[k], exp0[0], "half_adder.sum", k);
                check(ha_c[k], exp1[0], "half_adder.carry", k);
            end
            // subtraction: d = a-b ; diff = d mod 2 ; borrow = d < 0
            exp0 = ((ia - ib) % 2 + 2) % 2;  exp1 = ((ia - ib) < 0);
            for (k = 0; k < 5; k = k + 1) if (v[0] == 1'b0) begin
                check(hs_d[k], exp0[0], "half_subtractor.diff", k);
                check(hs_b[k], exp1[0], "half_subtractor.borrow", k);
            end
            exp0 = (ia + ib + ic) % 2;  exp1 = (ia + ib + ic) / 2;
            for (k = 0; k < 7; k = k + 1) begin
                check(fa_s[k], exp0[0], "full_adder.sum", k);
                check(fa_c[k], exp1[0], "full_adder.cout", k);
            end
            exp0 = (((ia - ib - ic) % 2) + 2) % 2;  exp1 = ((ia - ib - ic) < 0);
            for (k = 0; k < 7; k = k + 1) begin
                check(fs_d[k], exp0[0], "full_subtractor.diff", k);
                check(fs_b[k], exp1[0], "full_subtractor.bout", k);
            end
        end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
