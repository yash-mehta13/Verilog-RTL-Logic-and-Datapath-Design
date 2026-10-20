// Encoders.
//
// SIMPLE encoders assume exactly one input is high. `valid` is 1 only for a
// one-hot input; for all-zero or multi-hot inputs `valid`=0 and `y` is just the
// raw OR-gate result (it is NOT prioritized and must be ignored).
//
// PRIORITY encoders resolve multiple asserted inputs: the highest index wins.
// `valid` = any input asserted; with no input asserted y = 0 and valid = 0.
//
// plain = dataflow, _bh = behavioral.

module encoder4to2 (input [3:0] d, output [1:0] y, output valid);
    assign y[1] = d[2] | d[3];
    assign y[0] = d[1] | d[3];
    assign valid = (d != 4'b0000) && ((d & (d - 4'b0001)) == 4'b0000);
endmodule

module encoder4to2_bh (input [3:0] d, output reg [1:0] y, output reg valid);
    always @* begin
        valid = 1'b1;
        case (d)
            4'b0001: y = 2'd0;
            4'b0010: y = 2'd1;
            4'b0100: y = 2'd2;
            4'b1000: y = 2'd3;
            default: begin
                y = {d[2] | d[3], d[1] | d[3]};   // same raw OR equations
                valid = 1'b0;
            end
        endcase
    end
endmodule

module encoder8to3 (input [7:0] d, output [2:0] y, output valid);
    assign y[2] = d[4] | d[5] | d[6] | d[7];
    assign y[1] = d[2] | d[3] | d[6] | d[7];
    assign y[0] = d[1] | d[3] | d[5] | d[7];
    assign valid = (d != 8'b0) && ((d & (d - 8'b1)) == 8'b0);
endmodule

module encoder8to3_bh (input [7:0] d, output reg [2:0] y, output reg valid);
    always @* begin
        valid = 1'b1;
        case (d)
            8'b00000001: y = 3'd0;
            8'b00000010: y = 3'd1;
            8'b00000100: y = 3'd2;
            8'b00001000: y = 3'd3;
            8'b00010000: y = 3'd4;
            8'b00100000: y = 3'd5;
            8'b01000000: y = 3'd6;
            8'b10000000: y = 3'd7;
            default: begin
                y = {d[4] | d[5] | d[6] | d[7],
                     d[2] | d[3] | d[6] | d[7],
                     d[1] | d[3] | d[5] | d[7]};
                valid = 1'b0;
            end
        endcase
    end
endmodule

// ---------------------------------------------------------- priority
module priority_encoder4to2 (input [3:0] d, output [1:0] y, output valid);
    assign y[1] = d[3] | d[2];
    assign y[0] = d[3] | (~d[2] & d[1]);
    assign valid = |d;
endmodule

module priority_encoder4to2_bh (input [3:0] d, output reg [1:0] y, output reg valid);
    always @* begin
        valid = |d;
        casez (d)
            4'b1???: y = 2'd3;
            4'b01??: y = 2'd2;
            4'b001?: y = 2'd1;
            default: y = 2'd0;          // 0001 and 0000 (valid tells them apart)
        endcase
    end
endmodule

module priority_encoder8to3 (input [7:0] d, output [2:0] y, output valid);
    assign y[2] = d[7] | d[6] | d[5] | d[4];
    assign y[1] = d[7] | d[6] | (~d[5] & ~d[4] & (d[3] | d[2]));
    assign y[0] = d[7] | (~d[6] & d[5]) | (~d[6] & ~d[4] & d[3]) |
                  (~d[6] & ~d[4] & ~d[2] & d[1]);
    assign valid = |d;
endmodule

module priority_encoder8to3_bh (input [7:0] d, output reg [2:0] y, output reg valid);
    always @* begin
        valid = |d;
        casez (d)
            8'b1???????: y = 3'd7;
            8'b01??????: y = 3'd6;
            8'b001?????: y = 3'd5;
            8'b0001????: y = 3'd4;
            8'b00001???: y = 3'd3;
            8'b000001??: y = 3'd2;
            8'b0000001?: y = 3'd1;
            default:     y = 3'd0;
        endcase
    end
endmodule
