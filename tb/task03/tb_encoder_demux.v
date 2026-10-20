// Encoders (simple + priority) over ALL 16 / 256 input patterns and
// demultiplexers over all din/select combinations.
//  * simple encoder: `valid` must be 1 exactly for one-hot input; y is only
//    checked for one-hot input, and for every other pattern y must equal the
//    documented raw OR equations (proving no hidden priority).
//  * priority encoder: y = index of the highest set bit, valid = |d.
`timescale 1ns/1ps
module tb_encoder_demux;
    reg [7:0] d;
    reg       din;
    reg [1:0] s;
    integer errors, tests, i, j, hi, cnt;
    reg [8*256-1:0] vcdfile;

    wire [1:0] e42 [0:1];  wire [1:0] p42 [0:1];
    wire [2:0] e83 [0:1];  wire [2:0] p83 [0:1];
    wire [1:0] ev42; wire [1:0] ev42b; wire [1:0] pv42; wire [1:0] pv42b;
    wire [1:0] ev83; wire [1:0] ev83b; wire [1:0] pv83; wire [1:0] pv83b;
    wire v_e42_a, v_e42_b, v_p42_a, v_p42_b, v_e83_a, v_e83_b, v_p83_a, v_p83_b;

    encoder4to2          ue42a (.d(d[3:0]), .y(e42[0]), .valid(v_e42_a));
    encoder4to2_bh       ue42b (.d(d[3:0]), .y(e42[1]), .valid(v_e42_b));
    priority_encoder4to2    up42a (.d(d[3:0]), .y(p42[0]), .valid(v_p42_a));
    priority_encoder4to2_bh up42b (.d(d[3:0]), .y(p42[1]), .valid(v_p42_b));
    encoder8to3          ue83a (.d(d), .y(e83[0]), .valid(v_e83_a));
    encoder8to3_bh       ue83b (.d(d), .y(e83[1]), .valid(v_e83_b));
    priority_encoder8to3    up83a (.d(d), .y(p83[0]), .valid(v_p83_a));
    priority_encoder8to3_bh up83b (.d(d), .y(p83[1]), .valid(v_p83_b));

    wire [1:0] dm2 [0:2];
    wire [3:0] dm4 [0:2];
    demux1to2    um2a (.din(din), .s(s[0]), .y(dm2[0]));
    demux1to2_df um2b (.din(din), .s(s[0]), .y(dm2[1]));
    demux1to2_bh um2c (.din(din), .s(s[0]), .y(dm2[2]));
    demux1to4    um4a (.din(din), .s(s), .y(dm4[0]));
    demux1to4_df um4b (.din(din), .s(s), .y(dm4[1]));
    demux1to4_bh um4c (.din(din), .s(s), .y(dm4[2]));

    task chk;
        input integer got;
        input integer expd;
        input [8*20-1:0] name;
        input integer idx;
        begin
            tests = tests + 1;
            if (got !== expd) begin
                errors = errors + 1;
                $display("FAIL %0s[%0d] d=%b din=%b s=%0d got=%0d expected=%0d", name, idx, d, din, s, got, expd);
            end
        end
    endtask

    integer k, onehot, rawy;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_encoder_demux);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 256; i = i + 1) begin
            d = i; #1;
            // population count and highest set bit (independent loops)
            cnt = 0; hi = 0;
            for (j = 0; j < 8; j = j + 1) if (d[j]) begin cnt = cnt + 1; hi = j; end
            onehot = (cnt == 1);
            // ---- simple 8:3
            chk(v_e83_a, onehot, "enc8to3.valid", 0);
            chk(v_e83_b, onehot, "enc8to3_bh.valid", 0);
            rawy = (d[4]|d[5]|d[6]|d[7])*4 + (d[2]|d[3]|d[6]|d[7])*2 + (d[1]|d[3]|d[5]|d[7]);
            if (onehot) begin chk(e83[0], hi, "enc8to3.y", 0); chk(e83[1], hi, "enc8to3_bh.y", 1); end
            else        begin chk(e83[0], rawy, "enc8to3.raw", 0); chk(e83[1], rawy, "enc8to3_bh.raw", 1); end
            // ---- priority 8:3
            chk(v_p83_a, (cnt != 0), "pri8to3.valid", 0);
            chk(v_p83_b, (cnt != 0), "pri8to3_bh.valid", 0);
            chk(p83[0], hi, "pri8to3.y", 0);
            chk(p83[1], hi, "pri8to3_bh.y", 1);
            // ---- 4-input versions: only the low nibble matters
            if (i < 16) begin
                cnt = 0; hi = 0;
                for (j = 0; j < 4; j = j + 1) if (d[j]) begin cnt = cnt + 1; hi = j; end
                onehot = (cnt == 1);
                chk(v_e42_a, onehot, "enc4to2.valid", 0);
                chk(v_e42_b, onehot, "enc4to2_bh.valid", 0);
                rawy = (d[2]|d[3])*2 + (d[1]|d[3]);
                if (onehot) begin chk(e42[0], hi, "enc4to2.y", 0); chk(e42[1], hi, "enc4to2_bh.y", 1); end
                else        begin chk(e42[0], rawy, "enc4to2.raw", 0); chk(e42[1], rawy, "enc4to2_bh.raw", 1); end
                chk(v_p42_a, (cnt != 0), "pri4to2.valid", 0);
                chk(v_p42_b, (cnt != 0), "pri4to2_bh.valid", 0);
                chk(p42[0], hi, "pri4to2.y", 0);
                chk(p42[1], hi, "pri4to2_bh.y", 1);
            end
        end
        // fixed documented examples
        d = 8'b0000_0110; #1;   // two inputs asserted
        chk(v_e83_a, 0, "multi-hot valid", 0);
        chk(p83[0], 2, "multi-hot priority", 0);   // highest set bit is 2
        d = 8'b0; #1;           // nothing asserted
        chk(v_p83_a, 0, "all-zero valid", 0);
        chk(p83[0], 0, "all-zero y", 0);
        // ---- demultiplexers: every din / select combination
        for (i = 0; i < 2; i = i + 1)
            for (j = 0; j < 4; j = j + 1) begin
                din = i; s = j; #1;
                for (k = 0; k < 3; k = k + 1) begin
                    chk(dm2[k], i ? (1 << (j % 2)) : 0, "demux1to2", k);
                    chk(dm4[k], i ? (1 << j) : 0, "demux1to4", k);
                end
            end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
