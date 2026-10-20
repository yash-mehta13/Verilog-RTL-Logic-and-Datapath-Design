// Waveform testbench: 8:3 priority encoder and the simple 8:3 encoder side by
// side, showing that the priority encoder resolves multiple asserted inputs
// while the simple encoder flags them with valid = 0.
`timescale 1ns/1ps
module tb_priority_encoder_wave;
    reg  [7:0] d;
    wire [2:0] y_pri, y_simple;
    wire       v_pri, v_simple;
    integer errors;
    reg [8*256-1:0] vcdfile;
    priority_encoder8to3 dut_pri    (.d(d), .y(y_pri),    .valid(v_pri));
    encoder8to3          dut_simple (.d(d), .y(y_simple), .valid(v_simple));

    task apply;
        input [7:0] value;
        input [2:0] exp_y;
        input       exp_pv;
        input       exp_sv;
        begin
            d = value; #10;
            if (y_pri !== exp_y || v_pri !== exp_pv || v_simple !== exp_sv) begin
                errors = errors + 1;
                $display("FAIL d=%b y_pri=%0d v_pri=%b v_simple=%b", value, y_pri, v_pri, v_simple);
            end
        end
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_priority_encoder_wave);
        end
        errors = 0;
        apply(8'b0000_0000, 3'd0, 1'b0, 1'b0);   // nothing asserted
        apply(8'b0000_0001, 3'd0, 1'b1, 1'b1);
        apply(8'b0000_1000, 3'd3, 1'b1, 1'b1);
        apply(8'b1000_0000, 3'd7, 1'b1, 1'b1);
        apply(8'b0000_0110, 3'd2, 1'b1, 1'b0);   // two inputs: priority picks 2, simple flags invalid
        apply(8'b0101_0100, 3'd6, 1'b1, 1'b0);
        apply(8'b1111_1111, 3'd7, 1'b1, 1'b0);
        apply(8'b0000_0000, 3'd0, 1'b0, 1'b0);
        if (errors == 0) $display("RESULT: PASS tests=8");
        else             $display("RESULT: FAIL errors=%0d tests=8", errors);
        $finish;
    end
endmodule
