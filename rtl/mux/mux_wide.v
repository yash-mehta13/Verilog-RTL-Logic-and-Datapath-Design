// 4:1, 8:1 and 16:1 multiplexers. Data bus d[N-1:0]; Y = d[s].
// Selector convention (all sizes): s is an unsigned binary index, s[0] is the
// LSB. Hierarchical versions put s[0] on the first (leaf) 2:1 stage, so the
// result equals d[s] for every s.
//   plain name = hierarchical structural build from the next smaller MUX
//   _df        = direct dataflow  (assign y = d[s])
//   _bh        = direct behavioral (case)

module mux4 (input [3:0] d, input [1:0] s, output y);
    wire y0, y1;
    mux2 m0 (.d0(d[0]), .d1(d[1]), .s(s[0]), .y(y0));
    mux2 m1 (.d0(d[2]), .d1(d[3]), .s(s[0]), .y(y1));
    mux2 m2 (.d0(y0),   .d1(y1),   .s(s[1]), .y(y));
endmodule

module mux4_df (input [3:0] d, input [1:0] s, output y);
    assign y = d[s];
endmodule

module mux4_bh (input [3:0] d, input [1:0] s, output reg y);
    always @* begin
        case (s)
            2'd0:    y = d[0];
            2'd1:    y = d[1];
            2'd2:    y = d[2];
            default: y = d[3];
        endcase
    end
endmodule

module mux8 (input [7:0] d, input [2:0] s, output y);
    wire y0, y1;
    mux4 m0 (.d(d[3:0]), .s(s[1:0]), .y(y0));
    mux4 m1 (.d(d[7:4]), .s(s[1:0]), .y(y1));
    mux2 m2 (.d0(y0), .d1(y1), .s(s[2]), .y(y));
endmodule

module mux8_df (input [7:0] d, input [2:0] s, output y);
    assign y = d[s];
endmodule

module mux8_bh (input [7:0] d, input [2:0] s, output reg y);
    always @* begin
        case (s)
            3'd0:    y = d[0];
            3'd1:    y = d[1];
            3'd2:    y = d[2];
            3'd3:    y = d[3];
            3'd4:    y = d[4];
            3'd5:    y = d[5];
            3'd6:    y = d[6];
            default: y = d[7];
        endcase
    end
endmodule

// 16:1 built as 8:1 <- 4:1 <- 2:1 (15 two-to-one multiplexers in total).
module mux16 (input [15:0] d, input [3:0] s, output y);
    wire y0, y1;
    mux8 m0 (.d(d[7:0]),  .s(s[2:0]), .y(y0));
    mux8 m1 (.d(d[15:8]), .s(s[2:0]), .y(y1));
    mux2 m2 (.d0(y0), .d1(y1), .s(s[3]), .y(y));
endmodule

// Direct (non-hierarchical) 16:1
module mux16_df (input [15:0] d, input [3:0] s, output y);
    assign y = d[s];
endmodule

module mux16_bh (input [15:0] d, input [3:0] s, output reg y);
    integer k;
    always @* begin
        y = 1'b0;
        for (k = 0; k < 16; k = k + 1)
            if (s == k) y = d[k];
    end
endmodule
