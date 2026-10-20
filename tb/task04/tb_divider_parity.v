// Divider (WIDTH 4 and 8, exhaustive incl. divide-by-zero) and parity
// generator/checker (WIDTH 8, exhaustive). References: integer '/' and '%',
// and an explicit bit-counting loop for parity.
`timescale 1ns/1ps
module tb_divider_parity;
    reg  [3:0] n4, d4;
    reg  [7:0] n8, d8;
    wire [3:0] q4, r4;
    wire [7:0] q8, r8;
    wire       z4, z8;
    reg  [7:0] data;
    reg        pbit;
    wire       ev, od, err;
    integer errors, tests, i, j, ones, k;
    reg [8*256-1:0] vcdfile;

    divider_restoring #(.WIDTH(4)) u_div4 (.dividend(n4), .divisor(d4), .quotient(q4), .remainder(r4), .div_by_zero(z4));
    divider_restoring #(.WIDTH(8)) u_div8 (.dividend(n8), .divisor(d8), .quotient(q8), .remainder(r8), .div_by_zero(z8));
    parity_generator #(.WIDTH(8)) u_pg (.data(data), .even_p(ev), .odd_p(od));
    parity_checker_even #(.WIDTH(8)) u_pc (.data(data), .parity(pbit), .error(err));

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_divider_parity);
        end
        errors = 0; tests = 0;
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1) begin
                n4 = i; d4 = j; #1;
                tests = tests + 1;
                if (j == 0) begin
                    if (z4 !== 1'b1 || q4 !== 4'hF || r4 !== i[3:0]) begin
                        errors = errors + 1; $display("FAIL div4 %0d/0 q=%0d r=%0d z=%b", i, q4, r4, z4);
                    end
                end else if (z4 !== 1'b0 || q4 !== (i / j) || r4 !== (i % j)) begin
                    errors = errors + 1; $display("FAIL div4 %0d/%0d q=%0d r=%0d", i, j, q4, r4);
                end
            end
        for (i = 0; i < 256; i = i + 1)
            for (j = 0; j < 256; j = j + 1) begin
                n8 = i; d8 = j; #1;
                tests = tests + 1;
                if (j == 0) begin
                    if (z8 !== 1'b1 || q8 !== 8'hFF || r8 !== i[7:0]) begin
                        errors = errors + 1; $display("FAIL div8 %0d/0 q=%0d r=%0d z=%b", i, q8, r8, z8);
                    end
                end else if (z8 !== 1'b0 || q8 !== (i / j) || r8 !== (i % j)) begin
                    errors = errors + 1; $display("FAIL div8 %0d/%0d q=%0d r=%0d", i, j, q8, r8);
                end
            end
        for (i = 0; i < 256; i = i + 1) begin
            data = i;
            ones = 0;
            for (k = 0; k < 8; k = k + 1) if (i[k]) ones = ones + 1;
            #1;
            tests = tests + 4;
            if (ev !== (ones % 2)) begin errors = errors + 1; $display("FAIL even_p data=%b", data); end
            if (od !== ((ones + 1) % 2)) begin errors = errors + 1; $display("FAIL odd_p data=%b", data); end
            pbit = ev; #1;                       // data + even parity bit -> no error
            if (err !== 1'b0) begin errors = errors + 1; $display("FAIL checker (good) data=%b", data); end
            pbit = ~ev; #1;                      // flipped parity bit -> error
            if (err !== 1'b1) begin errors = errors + 1; $display("FAIL checker (bad) data=%b", data); end
        end
        if (errors == 0) $display("RESULT: PASS tests=%0d", tests);
        else             $display("RESULT: FAIL errors=%0d tests=%0d", errors, tests);
        $finish;
    end
endmodule
