// Signed Booth multiplier verification (N = 4 and N = 8).
//  * exhaustive: every signed operand pair (256 pairs at N=4, 65536 at N=8)
//  * protocol: busy/done timing, single-cycle done, product hold, start while
//    busy ignored, synchronous reset in the middle of an operation
// Expected product = signed integer multiplication in the testbench.
`timescale 1ns/1ps

module booth_checker #(parameter N = 4) (
    output reg        finished,
    output reg [31:0] errors,
    output reg [31:0] tests
);
    reg clk, rst_n, start;
    reg  [N-1:0] x, y;
    wire busy, done;
    wire [2*N-1:0] prod;
    booth_mult #(.N(N)) dut (.clk(clk), .rst_n(rst_n), .start(start),
        .multiplicand(x), .multiplier(y), .busy(busy), .done(done), .product(prod));

    initial clk = 0;
    always #5 clk = ~clk;

    integer sx, sy, sp, cycles, ix, iy;

    function integer to_signed;
        input integer v;
        input integer bits;
        begin
            to_signed = (v >= (1 << (bits - 1))) ? v - (1 << bits) : v;
        end
    endfunction

    task fail;
        input [8*40-1:0] msg;
        begin
            errors = errors + 1;
            if (errors < 20) $display("FAIL N=%0d %0s (x=%0d y=%0d prod=%0d)", N, msg,
                                      to_signed(x, N), to_signed(y, N), to_signed(prod, 2*N));
        end
    endtask

    // issue one multiplication, check protocol and result
    task mul;
        input integer xi;
        input integer yi;
        begin
            @(negedge clk);
            x = xi; y = yi; start = 1;
            @(negedge clk);
            start = 0;
            tests = tests + 1;
            if (busy !== 1'b1 || done !== 1'b0) fail("busy not high after start");
            cycles = 0;
            while (!done && cycles < N + 3) begin
                @(negedge clk);
                cycles = cycles + 1;
            end
            tests = tests + 1;
            if (cycles != N) fail("wrong latency");
            if (busy !== 1'b0) fail("busy not low at done");
            sx = to_signed(xi, N);
            sy = to_signed(yi, N);
            sp = to_signed(prod, 2*N);
            tests = tests + 1;
            if (sp !== sx * sy) begin
                fail("wrong product");
                $display("   expected %0d", sx * sy);
            end
            @(negedge clk);
            tests = tests + 1;
            if (done !== 1'b0) fail("done longer than 1 cycle");
            if (to_signed(prod, 2*N) !== sx * sy) fail("product not held");
        end
    endtask

    integer lo, hi;
    initial begin
        finished = 0; errors = 0; tests = 0;
        rst_n = 0; start = 0; x = 0; y = 0;
        repeat (3) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        tests = tests + 1;
        if (busy !== 0 || done !== 0 || prod !== 0) fail("reset state");
        lo = -(1 << (N - 1));
        hi = (1 << (N - 1)) - 1;
        // corner cases: min*min, min*max, max*max, 0, -1
        mul(1 << (N - 1), 1 << (N - 1));                   // (-2^(N-1))^2
        mul(1 << (N - 1), hi);
        mul(hi, 1 << (N - 1));
        mul(hi, hi);
        mul(0, 1 << (N - 1));
        mul((1 << N) - 1, (1 << N) - 1);                   // -1 * -1
        mul((1 << N) - 1, 1);
        // start while busy must be ignored
        @(negedge clk); x = 3; y = 5; start = 1;
        @(negedge clk); start = 0;
        repeat (2) @(negedge clk);
        x = 7; y = 7; start = 1;                            // would change result if accepted
        @(negedge clk); start = 0;
        while (!done) @(negedge clk);
        tests = tests + 1;
        if (to_signed(prod, 2*N) !== 15) fail("start-while-busy corrupted result");
        // synchronous reset in the middle of an operation
        @(negedge clk); x = 5; y = 3; start = 1;
        @(negedge clk); start = 0;
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        tests = tests + 1;
        if (busy !== 0 || done !== 0 || prod !== 0) fail("reset mid-operation");
        rst_n = 1;
        @(negedge clk);
        mul(2, 3);
        // exhaustive
        for (ix = 0; ix < (1 << N); ix = ix + 1)
            for (iy = 0; iy < (1 << N); iy = iy + 1)
                mul(ix, iy);
        finished = 1;
    end
endmodule

module tb_booth_mult;
    wire f4, f8;
    wire [31:0] e4, e8, t4, t8;
    reg [8*256-1:0] vcdfile;
    booth_checker #(.N(4)) b4 (.finished(f4), .errors(e4), .tests(t4));
    booth_checker #(.N(8)) b8 (.finished(f8), .errors(e8), .tests(t8));
    initial begin
        wait (f4 && f8);
        #1;
        $display("N=4: tests=%0d errors=%0d", t4, e4);
        $display("N=8: tests=%0d errors=%0d", t8, e8);
        if (e4 + e8 == 0) $display("RESULT: PASS tests=%0d", t4 + t8);
        else              $display("RESULT: FAIL errors=%0d tests=%0d", e4 + e8, t4 + t8);
        $finish;
    end
endmodule
