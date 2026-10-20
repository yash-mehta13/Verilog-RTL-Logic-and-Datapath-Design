// CLA adders vs integer reference. cla_adder4: all 512 vectors (sum, cout,
// group P/G). cla_adder16: directed corners + 200k fixed-seed random vectors
// (2^33 exhaustive vectors are impractical). Ripple adder run alongside.
`timescale 1ns/1ps
module tb_cla_adder;
    reg  [3:0]  a, b;
    reg         cin;
    reg  [15:0] a16, b16;
    reg         cin16;
    wire [3:0]  s_cla, s_bh, s_rip;
    wire        co_cla, co_bh, co_rip, gp, gg;
    wire [15:0] s16;
    wire        co16;
    integer errors, tests, i, j, k, expv;
    reg [8*256-1:0] vcdfile;

    cla_adder4    u0 (.a(a), .b(b), .cin(cin), .sum(s_cla), .cout(co_cla), .group_p(gp), .group_g(gg));
    cla_adder4_bh u1 (.a(a), .b(b), .cin(cin), .sum(s_bh), .cout(co_bh));
    ripple_adder4 u2 (.a(a), .b(b), .cin(cin), .sum(s_rip), .cout(co_rip));
    cla_adder16   u3 (.a(a16), .b(b16), .cin(cin16), .sum(s16), .cout(co16));

    task chk5;
        input [4:0] got;
        input integer expd;
        input [8*10-1:0] name;
        begin
            tests = tests + 1;
            if (got !== expd[4:0]) begin
                errors = errors + 1;
                $display("FAIL %0s a=%0d b=%0d cin=%b got=%0d expected=%0d", name, a, b, cin, got, expd);
            end
        end
    endtask

    task chk17;
        input integer expd;
        begin
            tests = tests + 1;
            if ({co16, s16} !== expd[16:0]) begin
                errors = errors + 1;
                $display("FAIL cla16 a=%0d b=%0d cin=%b got=%0d expected=%0d", a16, b16, cin16, {co16, s16}, expd);
            end
        end
    endtask

    reg [31:0] lfsr;
    integer gexp, pexp;
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_cla_adder);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                for (k = 0; k < 2; k = k + 1) begin
                    a = i; b = j; cin = k; #1;
                    expv = i + j + k;
                    chk5({co_cla, s_cla}, expv, "cla4");
                    chk5({co_bh, s_bh}, expv, "cla4_bh");
                    chk5({co_rip, s_rip}, expv, "ripple4");
                    // group generate = carry out when cin = 0; group propagate = (a+b == 15)
                    gexp = (i + j) > 15;
                    pexp = ((i ^ j) == 15);
                    tests = tests + 2;
                    if (gg !== gexp[0]) begin errors = errors + 1; $display("FAIL group_g a=%0d b=%0d", i, j); end
                    if (gp !== pexp[0]) begin errors = errors + 1; $display("FAIL group_p a=%0d b=%0d", i, j); end
                end
        // 16-bit corners
        a16 = 16'hFFFF; b16 = 16'h0001; cin16 = 0; #1; chk17(32'h10000);
        a16 = 16'hFFFF; b16 = 16'hFFFF; cin16 = 1; #1; chk17(32'h1FFFF);
        a16 = 16'h0000; b16 = 16'h0000; cin16 = 0; #1; chk17(0);
        a16 = 16'h7FFF; b16 = 16'h0001; cin16 = 0; #1; chk17(32'h8000);
        a16 = 16'h0FFF; b16 = 16'h0000; cin16 = 1; #1; chk17(32'h1000);   // carry ripples through 3 nibbles
        a16 = 16'hFFF0; b16 = 16'h0010; cin16 = 0; #1; chk17(32'h10000);
        // random
        lfsr = 32'hDEADBEEF;
        for (i = 0; i < 200000; i = i + 1) begin
            lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
            a16 = lfsr[15:0];
            lfsr = {lfsr[30:0], lfsr[31] ^ lfsr[21] ^ lfsr[1] ^ lfsr[0]};
            b16 = lfsr[15:0];
            cin16 = lfsr[7];
            #1;
            chk17(a16 + b16 + cin16);
        end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
