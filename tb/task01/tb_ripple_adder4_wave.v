// Waveform testbench for the 4-bit ripple-carry adder: a few directed
// vectors including a carry that ripples through every stage (15 + 0 + cin=1).
`timescale 1ns/1ps
module tb_ripple_adder4_wave;
    reg  [3:0] a, b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;
    integer errors, k;
    reg [8*256-1:0] vcdfile;
    ripple_adder4 dut (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));

    task apply;
        input [3:0] ta;
        input [3:0] tb_;
        input       tc;
        integer e;
        begin
            a = ta; b = tb_; cin = tc;
            #20;
            e = ta + tb_ + tc;
            if ({cout, sum} !== e[4:0]) begin
                errors = errors + 1;
                $display("FAIL %0d + %0d + %0d got %0d", ta, tb_, tc, {cout, sum});
            end
        end
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_ripple_adder4_wave);
        end
        errors = 0;
        apply(4'd0,  4'd0,  1'b0);
        apply(4'd3,  4'd4,  1'b0);
        apply(4'd7,  4'd9,  1'b0);
        apply(4'd13, 4'd7,  1'b0);   // 13 + 7 = 20 -> sum 4, cout 1
        apply(4'd15, 4'd0,  1'b1);   // carry ripples through all four stages
        apply(4'd15, 4'd15, 1'b1);   // largest case: 31
        if (errors == 0) $display("RESULT: PASS tests=6");
        else             $display("RESULT: FAIL errors=%0d tests=6", errors);
        $finish;
    end
endmodule
