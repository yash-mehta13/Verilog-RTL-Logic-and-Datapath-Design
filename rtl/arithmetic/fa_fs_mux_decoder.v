// Full adder / full subtractor from multiplexers and from a 3:8 decoder.
//
// MUX architecture: a 4:1 MUX with select {S1,S0} = {A,B}; the data inputs
// are functions of the remaining variable (CIN or BIN) - the standard
// "variable-entered" method. d index = {A,B}.
//   SUM / DIFF : idx 00->X, 01->~X, 10->~X, 11->X       (X = CIN or BIN)
//   COUT       : idx 00->0, 01->CIN, 10->CIN, 11->1
//   BOUT       : idx 00->BIN, 01->1, 10->0, 11->BIN
//
// Decoder architecture: 3:8 decoder on {A,B,X}; outputs are minterms m0..m7
//   SUM  = m1+m2+m4+m7   COUT = m3+m5+m6+m7
//   DIFF = m1+m2+m4+m7   BOUT = m1+m2+m3+m7

module full_adder_mux (input a, input b, input cin, output sum, output cout);
    wire ncin;
    not g_n (ncin, cin);
    mux4 m_sum  (.d({cin, ncin, ncin, cin}),    .s({a, b}), .y(sum));
    mux4 m_cout (.d({1'b1, cin, cin, 1'b0}),    .s({a, b}), .y(cout));
endmodule

module full_subtractor_mux (input a, input b, input bin, output diff, output bout);
    wire nbin;
    not g_n (nbin, bin);
    mux4 m_diff (.d({bin, nbin, nbin, bin}),    .s({a, b}), .y(diff));
    mux4 m_bout (.d({bin, 1'b0, 1'b1, bin}),    .s({a, b}), .y(bout));
endmodule

module full_adder_decoder (input a, input b, input cin, output sum, output cout);
    wire [7:0] m;
    decoder3to8 dec (.a({a, b, cin}), .en(1'b1), .y(m));
    or g_sum  (sum,  m[1], m[2], m[4], m[7]);
    or g_cout (cout, m[3], m[5], m[6], m[7]);
endmodule

module full_subtractor_decoder (input a, input b, input bin, output diff, output bout);
    wire [7:0] m;
    decoder3to8 dec (.a({a, b, bin}), .en(1'b1), .y(m));
    or g_diff (diff, m[1], m[2], m[4], m[7]);
    or g_bout (bout, m[1], m[2], m[3], m[7]);
endmodule
