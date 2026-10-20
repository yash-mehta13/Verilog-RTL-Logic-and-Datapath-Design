// Exhaustive decoder test: every address, enable on/off, all styles, active
// high and active low, plus the four internal 2:4 gate-level realizations.
// Expected output: one-hot (1 << addr) when enabled, else zero - computed in
// the testbench without using the DUTs.
`timescale 1ns/1ps
module tb_decoder;
    reg [3:0] a;
    reg       en;
    integer errors, tests, i, e;
    reg [8*256-1:0] vcdfile;

    wire [3:0]  d24 [0:2];
    wire [7:0]  d38 [0:2];
    wire [15:0] d416 [0:2];
    wire [1:0]  d12  [0:1];
    wire [3:0]  d24n;
    wire [7:0]  d38n;
    wire [15:0] d416n;
    wire [3:0]  i_sop, i_nor, i_pos, i_nand;

    decoder1to2     u12a (.a(a[0]), .en(en), .y(d12[0]));
    decoder1to2_df  u12b (.a(a[0]), .en(en), .y(d12[1]));
    decoder2to4     u24a (.a(a[1:0]), .en(en), .y(d24[0]));
    decoder2to4_df  u24b (.a(a[1:0]), .en(en), .y(d24[1]));
    decoder2to4_bh  u24c (.a(a[1:0]), .en(en), .y(d24[2]));
    decoder3to8     u38a (.a(a[2:0]), .en(en), .y(d38[0]));
    decoder3to8_df  u38b (.a(a[2:0]), .en(en), .y(d38[1]));
    decoder3to8_bh  u38c (.a(a[2:0]), .en(en), .y(d38[2]));
    decoder4to16    u416a (.a(a), .en(en), .y(d416[0]));
    decoder4to16_df u416b (.a(a), .en(en), .y(d416[1]));
    decoder4to16_bh u416c (.a(a), .en(en), .y(d416[2]));
    // active-low versions: en_n = ~en
    decoder2to4_n   u24n  (.a(a[1:0]), .en_n(~en), .y_n(d24n));
    decoder3to8_n   u38n  (.a(a[2:0]), .en_n(~en), .y_n(d38n));
    decoder4to16_n  u416n (.a(a), .en_n(~en), .y_n(d416n));
    // internal gate-level 2:4 (no enable)
    decoder2to4_sop  us (.a(a[1:0]), .y(i_sop));
    decoder2to4_nor  un (.a(a[1:0]), .y(i_nor));
    decoder2to4_pos  up (.a(a[1:0]), .y_n(i_pos));
    decoder2to4_nand ud (.a(a[1:0]), .y_n(i_nand));

    task chk;
        input integer got;
        input integer expd;
        input [8*16-1:0] name;
        input integer idx;
        begin
            tests = tests + 1;
            if (got !== expd) begin
                errors = errors + 1;
                $display("FAIL %0s[%0d] a=%0d en=%b got=%b expected=%b", name, idx, a, en, got[15:0], expd[15:0]);
            end
        end
    endtask

    integer k, ex;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_decoder);
        end
        errors = 0; tests = 0;
        for (e = 0; e < 2; e = e + 1)
            for (i = 0; i < 16; i = i + 1) begin
                a = i; en = e; #1;
                // 1:2 (uses a[0])
                ex = e ? (1 << (i % 2)) : 0;
                for (k = 0; k < 2; k = k + 1) chk(d12[k], ex, "dec1to2", k);
                ex = e ? (1 << (i % 4)) : 0;
                for (k = 0; k < 3; k = k + 1) chk(d24[k], ex, "dec2to4", k);
                chk(d24n, ~ex & 4'hF, "dec2to4_n", 0);
                ex = e ? (1 << (i % 8)) : 0;
                for (k = 0; k < 3; k = k + 1) chk(d38[k], ex, "dec3to8", k);
                chk(d38n, ~ex & 8'hFF, "dec3to8_n", 0);
                ex = e ? (1 << i) : 0;
                for (k = 0; k < 3; k = k + 1) chk(d416[k], ex, "dec4to16", k);
                chk(d416n, ~ex & 16'hFFFF, "dec4to16_n", 0);
                // internal 2:4 (always enabled)
                ex = 1 << (i % 4);
                chk(i_sop, ex, "dec_sop", 0);
                chk(i_nor, ex, "dec_nor", 0);
                chk(i_pos, ~ex & 4'hF, "dec_pos", 0);
                chk(i_nand, ~ex & 4'hF, "dec_nand", 0);
                // exactly one output asserted when enabled
                if (e) begin
                    tests = tests + 1;
                    if ((d416[0] & (d416[0] - 1)) != 0 || d416[0] == 0) begin
                        errors = errors + 1; $display("FAIL 4:16 not one-hot a=%0d", i);
                    end
                end
            end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
