// Demultiplexers (active-high). din is routed to output y[s]; every other
// output is 0. A demultiplexer is a decoder whose enable input is the data.
// plain = structural (built from the decoder), _df dataflow, _bh behavioral.

module demux1to2 (input din, input s, output [1:0] y);
    decoder1to2 core (.a(s), .en(din), .y(y));
endmodule

module demux1to2_df (input din, input s, output [1:0] y);
    assign y = {din & s, din & ~s};
endmodule

module demux1to2_bh (input din, input s, output reg [1:0] y);
    always @* begin
        y = 2'b00;
        if (s) y[1] = din;
        else   y[0] = din;
    end
endmodule

module demux1to4 (input din, input [1:0] s, output [3:0] y);
    decoder2to4 core (.a(s), .en(din), .y(y));
endmodule

module demux1to4_df (input din, input [1:0] s, output [3:0] y);
    assign y = din ? (4'b0001 << s) : 4'b0000;
endmodule

module demux1to4_bh (input din, input [1:0] s, output reg [3:0] y);
    always @* begin
        y = 4'b0000;
        y[s] = din;
    end
endmodule
