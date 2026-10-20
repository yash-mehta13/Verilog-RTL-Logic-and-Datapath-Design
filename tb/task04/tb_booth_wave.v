// Waveform + trace testbench for the 4-bit signed Booth multiplier.
// Operation 1: (-3) x 5 = -15   (worked example in docs/task04-alu-fpga.md)
// Operation 2: 7 x (-8) = -56   (multiplier at its most negative value)
// Prints a step-by-step trace from the DUT registers (simulation-only
// hierarchical references - not part of the synthesizable design).
`timescale 1ns/1ps
module tb_booth_wave;
    localparam N = 4;
    reg clk, rst_n, start;
    reg  [N-1:0] x, y;
    wire busy, done;
    wire [2*N-1:0] prod;
    integer errors;
    reg [8*256-1:0] vcdfile;
    booth_mult #(.N(N)) dut (.clk(clk), .rst_n(rst_n), .start(start),
        .multiplicand(x), .multiplier(y), .busy(busy), .done(done), .product(prod));

    initial clk = 0;
    always #5 clk = ~clk;

    // trace the register state before every step
    always @(negedge clk) if (dut.busy)
        $display("TRACE count=%0d A=%b Q=%b Q-1=%b action=%s", dut.count, dut.a_reg, dut.q_reg, dut.q_1,
                 ({dut.q_reg[0], dut.q_1} == 2'b01) ? "A=A+M" :
                 ({dut.q_reg[0], dut.q_1} == 2'b10) ? "A=A-M" : "none ");

    task mul;
        input [N-1:0] mx;
        input [N-1:0] my;
        input integer expect_prod;
        begin
            @(negedge clk); x = mx; y = my; start = 1;
            @(negedge clk); start = 0;
            $display("TRACE multiplicand M=%b (%0d)  multiplier Q=%b (%0d)", mx, $signed(mx), my, $signed(my));
            while (!done) @(negedge clk);
            $display("TRACE product=%b (%0d) expected=%0d", prod, $signed(prod), expect_prod);
            if ($signed(prod) !== expect_prod) errors = errors + 1;
            @(negedge clk);
        end
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_booth_wave);
        end
        errors = 0; rst_n = 0; start = 0; x = 0; y = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        mul(4'b1101, 4'b0101, -15);     // -3 x 5
        mul(4'b0111, 4'b1000, -56);     // 7 x -8
        if (errors == 0) $display("RESULT: PASS tests=2");
        else             $display("RESULT: FAIL errors=%0d tests=2", errors);
        $finish;
    end
endmodule
