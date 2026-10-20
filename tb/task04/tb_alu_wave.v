// Waveform testbench for the 8-bit ALU: all eight opcodes on a fixed operand
// pair, then the flag corner cases (carry, signed overflow, borrow, zero).
`include "alu_opcodes.vh"
`timescale 1ns/1ps
module tb_alu_wave;
    reg  [7:0] a, b;
    reg  [2:0] op;
    wire [7:0] y;
    wire carry, borrow, overflow, zero, negative;
    integer errors;
    reg [8*256-1:0] vcdfile;
    alu_8bit dut (.a(a), .b(b), .op(op), .y(y), .carry(carry), .borrow(borrow),
                  .overflow(overflow), .zero(zero), .negative(negative));

    // expected: y, then flags {carry, borrow, overflow, zero, negative}
    task apply;
        input [7:0] ta;
        input [7:0] tb_;
        input [2:0] top;
        input [7:0] ey;
        input [4:0] eflags;
        begin
            a = ta; b = tb_; op = top; #10;
            if (y !== ey || {carry, borrow, overflow, zero, negative} !== eflags) begin
                errors = errors + 1;
                $display("FAIL op=%0d a=%h b=%h y=%h flags=%b (expected y=%h flags=%b)", top, ta, tb_, y, {carry, borrow, overflow, zero, negative}, ey, eflags);
            end
        end
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcdfile)) begin
            $dumpfile(vcdfile);
            $dumpvars(0, tb_alu_wave);
        end
        errors = 0;
        // a = 0x5A, b = 0x3C through all opcodes     flags: C B V Z N
        apply(8'h5A, 8'h3C, `ALU_OP_ADD,   8'h96, 5'b00101);   // 90+60=150: signed overflow, negative
        apply(8'h5A, 8'h3C, `ALU_OP_SUB,   8'h1E, 5'b00000);
        apply(8'h5A, 8'h3C, `ALU_OP_AND,   8'h18, 5'b00000);
        apply(8'h5A, 8'h3C, `ALU_OP_OR,    8'h7E, 5'b00000);
        apply(8'h5A, 8'h3C, `ALU_OP_XOR,   8'h66, 5'b00000);
        apply(8'h5A, 8'h3C, `ALU_OP_XNOR,  8'h99, 5'b00001);
        apply(8'h5A, 8'h3C, `ALU_OP_NOTA,  8'hA5, 5'b00001);
        apply(8'h5A, 8'h3C, `ALU_OP_PASSB, 8'h3C, 5'b00000);
        // flag corner cases
        apply(8'hFF, 8'h01, `ALU_OP_ADD,   8'h00, 5'b10010);   // unsigned carry, result zero
        apply(8'h7F, 8'h01, `ALU_OP_ADD,   8'h80, 5'b00101);   // signed overflow
        apply(8'h10, 8'h20, `ALU_OP_SUB,   8'hF0, 5'b01001);   // unsigned borrow, negative
        apply(8'h80, 8'h01, `ALU_OP_SUB,   8'h7F, 5'b00100);   // signed overflow on subtract
        apply(8'h33, 8'h33, `ALU_OP_SUB,   8'h00, 5'b00010);   // zero result
        if (errors == 0) $display("RESULT: PASS tests=13");
        else             $display("RESULT: FAIL errors=%0d tests=13", errors);
        $finish;
    end
endmodule
