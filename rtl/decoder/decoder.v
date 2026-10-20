// Binary decoders with active-high enable `en` and active-high outputs.
// Exactly one y[i] is 1 (i = address) when en=1; all outputs 0 when en=0.
// plain = hierarchical structural, _df = dataflow, _bh = behavioral.
//   2:4  <- 1:2 steering stage + two 1:2 decoders
//   3:8  <- 1:2 steering stage + two 2:4 decoders
//   4:16 <- 1:2 steering stage + two 3:8 decoders
// The 1:2 stage decodes the MSB address bit and drives the enables of the
// two lower-order decoders (MSB=0 -> low half, MSB=1 -> high half).

module decoder1to2 (input a, input en, output [1:0] y);
    wire na;
    not g_na (na, a);
    and g_y0 (y[0], en, na);
    and g_y1 (y[1], en, a);
endmodule

module decoder2to4 (input [1:0] a, input en, output [3:0] y);
    wire [1:0] e;
    decoder1to2 hi (.a(a[1]), .en(en),   .y(e));
    decoder1to2 lo (.a(a[0]), .en(e[0]), .y(y[1:0]));
    decoder1to2 up (.a(a[0]), .en(e[1]), .y(y[3:2]));
endmodule

module decoder3to8 (input [2:0] a, input en, output [7:0] y);
    wire [1:0] e;
    decoder1to2 hi (.a(a[2]), .en(en),   .y(e));
    decoder2to4 lo (.a(a[1:0]), .en(e[0]), .y(y[3:0]));
    decoder2to4 up (.a(a[1:0]), .en(e[1]), .y(y[7:4]));
endmodule

module decoder4to16 (input [3:0] a, input en, output [15:0] y);
    wire [1:0] e;
    decoder1to2 hi (.a(a[3]), .en(en),   .y(e));
    decoder3to8 lo (.a(a[2:0]), .en(e[0]), .y(y[7:0]));
    decoder3to8 up (.a(a[2:0]), .en(e[1]), .y(y[15:8]));
endmodule

// ---- dataflow
module decoder2to4_df (input [1:0] a, input en, output [3:0] y);
    assign y = en ? (4'b0001 << a) : 4'b0000;
endmodule
module decoder3to8_df (input [2:0] a, input en, output [7:0] y);
    assign y = en ? (8'b00000001 << a) : 8'b00000000;
endmodule
module decoder4to16_df (input [3:0] a, input en, output [15:0] y);
    assign y = en ? (16'h0001 << a) : 16'h0000;
endmodule

// ---- behavioral
module decoder2to4_bh (input [1:0] a, input en, output reg [3:0] y);
    always @* begin
        y = 4'b0000;
        if (en) begin
            case (a)
                2'd0: y = 4'b0001;
                2'd1: y = 4'b0010;
                2'd2: y = 4'b0100;
                2'd3: y = 4'b1000;
            endcase
        end
    end
endmodule

module decoder3to8_bh (input [2:0] a, input en, output reg [7:0] y);
    integer k;
    always @* begin
        y = 8'b0;
        for (k = 0; k < 8; k = k + 1)
            if (en && a == k) y[k] = 1'b1;
    end
endmodule

module decoder4to16_bh (input [3:0] a, input en, output reg [15:0] y);
    integer k;
    always @* begin
        y = 16'b0;
        for (k = 0; k < 16; k = k + 1)
            if (en && a == k) y[k] = 1'b1;
    end
endmodule

// ---- active-low wrappers: en_n = 0 enables, selected output is 0, others 1.
module decoder2to4_n (input [1:0] a, input en_n, output [3:0] y_n);
    wire [3:0] y;
    decoder2to4 core (.a(a), .en(~en_n), .y(y));
    assign y_n = ~y;
endmodule
module decoder3to8_n (input [2:0] a, input en_n, output [7:0] y_n);
    wire [7:0] y;
    decoder3to8 core (.a(a), .en(~en_n), .y(y));
    assign y_n = ~y;
endmodule
module decoder4to16_n (input [3:0] a, input en_n, output [15:0] y_n);
    wire [15:0] y;
    decoder4to16 core (.a(a), .en(~en_n), .y(y));
    assign y_n = ~y;
endmodule

// ---- 1:2 variants
module decoder1to2_df (input a, input en, output [1:0] y);
    assign y = {en & a, en & ~a};
endmodule
