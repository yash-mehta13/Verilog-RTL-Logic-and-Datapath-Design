// Simulation-only check of the board-agnostic FPGA top levels (does not
// involve Quartus or hardware).
`timescale 1ns/1ps
module tb_fpga_tops;
    reg  [8:0] sw;
    wire [1:0] ha_led;
    wire [8:0] alu_led;
    integer errors, tests, i;
    integer ia, ib, ey;
    fpga_half_adder_top ha (.sw(sw[1:0]), .led(ha_led));
    fpga_alu4_top       al (.sw(sw), .led(alu_led));
    initial begin
        errors = 0; tests = 0;
        for (i = 0; i < 512; i = i + 1) begin
            sw = i; #1;
            tests = tests + 1;
            if (ha_led !== {sw[0] & sw[1], sw[0] ^ sw[1]}) begin
                errors = errors + 1; $display("FAIL half adder top sw=%b", sw[1:0]);
            end
            // ALU top: add (op 000) and sub (op 001) cross-checked against integers
            ia = sw[2:0]; ib = sw[5:3];
            if (sw[8:6] == 3'b000) begin
                ey = ia + ib;
                tests = tests + 1;
                if (alu_led[3:0] !== ey[3:0] || alu_led[4] !== 1'b0) begin
                    errors = errors + 1; $display("FAIL alu top add sw=%b", sw);
                end
            end
            if (sw[8:6] == 3'b001) begin
                ey = ia - ib;
                tests = tests + 1;
                if (alu_led[3:0] !== ey[3:0] || alu_led[5] !== (ia < ib)) begin
                    errors = errors + 1; $display("FAIL alu top sub sw=%b", sw);
                end
            end
        end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
