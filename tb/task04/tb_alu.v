// Exhaustive ALU verification at WIDTH = 1, 4 and 8: every (a, b, op)
// combination (8 * 4^WIDTH... = 524288 vectors at 8 bits). Both the
// behavioral ALU (via the fixed-width wrappers) and the structural ALU
// (alu_st) are compared with an independent integer reference model that
// derives carry/borrow/overflow from wide signed arithmetic.
`include "alu_opcodes.vh"
`timescale 1ns/1ps

module alu_checker #(parameter WIDTH = 4) (
    output reg        done,
    output reg [31:0] errors,
    output reg [31:0] tests
);
    reg  [WIDTH-1:0] a, b;
    reg  [2:0]       op;
    wire [WIDTH-1:0] y1, y2;
    wire c1, b1, o1, z1, n1, c2, b2, o2, z2, n2;

    generate
        if (WIDTH == 1) begin : w1
            alu_1bit dut (.a(a), .b(b), .op(op), .y(y1), .carry(c1), .borrow(b1),
                          .overflow(o1), .zero(z1), .negative(n1));
        end else if (WIDTH == 4) begin : w4
            alu_4bit dut (.a(a), .b(b), .op(op), .y(y1), .carry(c1), .borrow(b1),
                          .overflow(o1), .zero(z1), .negative(n1));
        end else if (WIDTH == 8) begin : w8
            alu_8bit dut (.a(a), .b(b), .op(op), .y(y1), .carry(c1), .borrow(b1),
                          .overflow(o1), .zero(z1), .negative(n1));
        end else begin : wn
            alu #(.WIDTH(WIDTH)) dut (.a(a), .b(b), .op(op), .y(y1), .carry(c1), .borrow(b1),
                          .overflow(o1), .zero(z1), .negative(n1));
        end
    endgenerate
    alu_st #(.WIDTH(WIDTH)) dut_st (.a(a), .b(b), .op(op), .y(y2), .carry(c2), .borrow(b2),
                          .overflow(o2), .zero(z2), .negative(n2));

    integer ia, ib, io, mod, half, sa, sb, full, sres;
    integer ey, ec, eb, eo, ez, en;

    task compare;
        input [8*8-1:0] who;
        input [WIDTH-1:0] gy;
        input gc, gb, go, gz, gn;
        begin
            tests = tests + 1;
            if (gy !== ey[WIDTH-1:0] || gc !== ec[0] || gb !== eb[0] ||
                go !== eo[0] || gz !== ez[0] || gn !== en[0]) begin
                errors = errors + 1;
                if (errors < 20)
                    $display("FAIL %0s W=%0d op=%0d a=%0d b=%0d got y=%0d c=%b b=%b v=%b z=%b n=%b exp y=%0d c=%0d b=%0d v=%0d z=%0d n=%0d",
                        who, WIDTH, op, a, b, gy, gc, gb, go, gz, gn, ey, ec, eb, eo, ez, en);
            end
        end
    endtask

    initial begin
        done = 0; errors = 0; tests = 0;
        mod  = 1 << WIDTH;
        half = 1 << (WIDTH - 1);
        for (io = 0; io < 8; io = io + 1)
            for (ia = 0; ia < mod; ia = ia + 1)
                for (ib = 0; ib < mod; ib = ib + 1) begin
                    a = ia; b = ib; op = io; #1;
                    sa = (ia >= half) ? ia - mod : ia;    // two's-complement values
                    sb = (ib >= half) ? ib - mod : ib;
                    ec = 0; eb = 0; eo = 0; ey = 0;
                    case (io)
                        0: begin   // ADD
                            full = ia + ib;
                            ey = full % mod;
                            ec = (full >= mod);
                            sres = sa + sb;
                            eo = (sres < -half) || (sres > half - 1);
                        end
                        1: begin   // SUB
                            full = ia - ib;
                            ey = ((full % mod) + mod) % mod;
                            eb = (ia < ib);
                            sres = sa - sb;
                            eo = (sres < -half) || (sres > half - 1);
                        end
                        2: ey = ia & ib;
                        3: ey = ia | ib;
                        4: ey = ia ^ ib;
                        5: ey = (~(ia ^ ib)) & (mod - 1);
                        6: ey = (~ia) & (mod - 1);
                        7: ey = ib;
                    endcase
                    ez = (ey == 0);
                    en = (ey >= half);
                    compare("alu", y1, c1, b1, o1, z1, n1);
                    compare("alu_st", y2, c2, b2, o2, z2, n2);
                end
        done = 1;
    end
endmodule

module tb_alu;
    wire d1, d4, d8;
    wire [31:0] e1, e4, e8, t1, t4, t8;
    reg [8*256-1:0] vcdfile;
    alu_checker #(.WIDTH(1)) c1 (.done(d1), .errors(e1), .tests(t1));
    alu_checker #(.WIDTH(4)) c4 (.done(d4), .errors(e4), .tests(t4));
    alu_checker #(.WIDTH(8)) c8 (.done(d8), .errors(e8), .tests(t8));
    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(1, tb_alu);
        end
        wait (d1 && d4 && d8);
        #1;
        $display("width 1: tests=%0d errors=%0d", t1, e1);
        $display("width 4: tests=%0d errors=%0d", t4, e4);
        $display("width 8: tests=%0d errors=%0d", t8, e8);
        if (e1 + e4 + e8 == 0) $display("RESULT: PASS tests=%0d", t1 + t4 + t8);
        else                   $display("RESULT: FAIL errors=%0d tests=%0d", e1 + e4 + e8, t1 + t4 + t8);
        $finish;
    end
endmodule
