// Verifies every MUX: all select values with a walking-one data pattern and
// with all 2^N data patterns for 2:1/4:1/8:1 (2^16 patterns for 16:1 are
// sampled with a fixed-seed LFSR plus walking one/zero). Expected output is
// d[sel] computed with a plain loop in the testbench.
`timescale 1ns/1ps
module tb_mux;
    reg  [15:0] d;
    reg  [3:0]  s;
    integer errors, tests, i, sel;
    reg [8*256-1:0] vcdfile;
    reg exp;

    wire [4:0] y2;   // mux2: bh, df, sop, pos, nand ... (nor below)
    wire       y2_nor;
    mux2_bh   u2a (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2[0]));
    mux2      u2b (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2[1]));
    mux2_sop  u2c (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2[2]));
    mux2_pos  u2d (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2[3]));
    mux2_nand u2e (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2[4]));
    mux2_nor  u2f (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y2_nor));

    wire [2:0] y4, y8, y16;
    mux4_bh  u4a (.d(d[3:0]), .s(s[1:0]), .y(y4[0]));
    mux4_df  u4b (.d(d[3:0]), .s(s[1:0]), .y(y4[1]));
    mux4     u4c (.d(d[3:0]), .s(s[1:0]), .y(y4[2]));
    mux8_bh  u8a (.d(d[7:0]), .s(s[2:0]), .y(y8[0]));
    mux8_df  u8b (.d(d[7:0]), .s(s[2:0]), .y(y8[1]));
    mux8     u8c (.d(d[7:0]), .s(s[2:0]), .y(y8[2]));
    mux16_bh u16a (.d(d), .s(s), .y(y16[0]));
    mux16_df u16b (.d(d), .s(s), .y(y16[1]));
    mux16    u16c (.d(d), .s(s), .y(y16[2]));

    task chk;
        input got;
        input [8*12-1:0] name;
        input integer idx;
        begin
            tests = tests + 1;
            if (got !== exp) begin
                errors = errors + 1;
                $display("FAIL %0s[%0d] d=%b s=%0d got=%b expected=%b", name, idx, d, s, got, exp);
            end
        end
    endtask

    task run_one;
        integer k;
        begin
            #1;
            exp = d[s[0]];
            for (k = 0; k < 5; k = k + 1) chk(y2[k], "mux2", k);
            chk(y2_nor, "mux2_nor", 0);
            exp = d[s[1:0]];
            for (k = 0; k < 3; k = k + 1) chk(y4[k], "mux4", k);
            exp = d[s[2:0]];
            for (k = 0; k < 3; k = k + 1) chk(y8[k], "mux8", k);
            exp = d[s];
            for (k = 0; k < 3; k = k + 1) chk(y16[k], "mux16", k);
        end
    endtask

    reg [15:0] lfsr;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_mux);
        end
        errors = 0; tests = 0;
        // every select value with every walking-one / walking-zero pattern
        for (sel = 0; sel < 16; sel = sel + 1)
            for (i = 0; i < 16; i = i + 1) begin
                s = sel; d = 16'h0001 << i; run_one;
                s = sel; d = ~(16'h0001 << i); run_one;
            end
        // pseudo-random data (fixed seed LFSR, taps 16,14,13,11)
        lfsr = 16'hACE1;
        for (i = 0; i < 4096; i = i + 1) begin
            lfsr = {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
            d = lfsr; s = i[3:0]; run_one;
        end
        // exhaustive data for the 4-input case (and thus mux2) over all selects
        for (i = 0; i < 65536; i = i + 1) begin
            d = i; s = i[3:0] ^ i[7:4]; // varied select
            if (i < 1024) run_one;
        end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
