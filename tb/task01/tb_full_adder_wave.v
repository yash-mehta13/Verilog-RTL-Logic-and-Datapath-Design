// Waveform testbench: all 8 input combinations of the structural full adder
// (two half adders + OR) and the NAND-only full adder, 10 ns apart.
// Self-checking; the VCD (+vcd=<file>) is what the waveform figure is made from.
`timescale 1ns/1ps
module tb_full_adder_wave;
    reg  a, b, cin;
    wire sum, cout, sum_nand, cout_nand;
    integer i, errors, exp;
    reg [8*256-1:0] vcdfile;
    full_adder      dut      (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
    full_adder_nand dut_nand (.a(a), .b(b), .cin(cin), .sum(sum_nand), .cout(cout_nand));
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_full_adder_wave);
        end
        errors = 0;
        for (i = 0; i < 8; i = i + 1) begin
            {a, b, cin} = i[2:0];
            #10;
            exp = a + b + cin;
            if ({cout, sum} !== exp[1:0] || {cout_nand, sum_nand} !== exp[1:0]) begin
                errors = errors + 1;
                $display("FAIL a=%b b=%b cin=%b", a, b, cin);
            end
        end
        #10;
        if (errors == 0) $display("RESULT: PASS tests=8");
        else             $display("RESULT: FAIL errors=%0d tests=8", errors);
        $finish;
    end
endmodule
