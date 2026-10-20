// Waveform testbench: 4:16 decoder (hierarchical, from two 3:8 decoders),
// all 16 addresses with enable high, then enable low for two addresses.
`timescale 1ns/1ps
module tb_decoder_wave;
    reg  [3:0]  a;
    reg         en;
    wire [15:0] y;
    integer i, errors;
    reg [8*256-1:0] vcdfile;
    decoder4to16 dut (.a(a), .en(en), .y(y));
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_decoder_wave);
        end
        errors = 0; en = 1;
        for (i = 0; i < 16; i = i + 1) begin
            a = i; #10;
            if (y !== (16'h0001 << i)) begin errors = errors + 1; $display("FAIL a=%0d y=%b", i, y); end
        end
        en = 0; a = 4'd5; #10;
        if (y !== 16'h0000) begin errors = errors + 1; $display("FAIL disabled y=%b", y); end
        a = 4'd12; #10;
        if (y !== 16'h0000) begin errors = errors + 1; $display("FAIL disabled y=%b", y); end
        en = 1; #10;
        if (y !== (16'h0001 << 12)) begin errors = errors + 1; $display("FAIL re-enable y=%b", y); end
        #10;
        if (errors == 0) $display("RESULT: PASS tests=19");
        else             $display("RESULT: FAIL errors=%0d tests=19", errors);
        $finish;
    end
endmodule
