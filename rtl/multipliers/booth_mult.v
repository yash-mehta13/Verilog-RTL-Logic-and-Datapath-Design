// Radix-2 Booth multiplier for SIGNED two's-complement operands.
//
// Handshake / timing
//   * Operands are sampled on the clock edge where `start`=1 while idle
//     (busy=0). `start` while busy is ignored (no queuing, no restart).
//   * busy goes high the cycle after the accepting edge and stays high for
//     exactly N cycles (one add/sub/shift step per cycle).
//   * `done` is a single-cycle pulse, coincident with busy falling.
//     `product` (2N-bit signed) is valid whenever done=1 and keeps its value
//     until the next operation completes.
//   * rst_n (synchronous, active low) clears everything, including product.
//   * Latency from the accepting edge to done: N+1 clock edges.
//
// Datapath: A is N+1 bits (extra bit so A+M / A-M can never overflow),
// Q holds the multiplier, Q_1 is the extra bit appended to the right of Q.
// Each step examines {Q[0], Q_1}: 01 -> A=A+M, 10 -> A=A-M, 00/11 -> no add;
// then {A,Q,Q_1} is shifted right arithmetically by one bit.
module booth_mult #(
    parameter N = 8
) (
    input                    clk,
    input                    rst_n,
    input                    start,
    input      [N-1:0]       multiplicand,   // signed
    input      [N-1:0]       multiplier,     // signed
    output reg               busy,
    output reg               done,
    output reg [2*N-1:0]     product         // signed
);
    reg [N:0]   a_reg;
    reg [N-1:0] q_reg;
    reg         q_1;
    reg [N:0]   m_reg;                         // sign-extended multiplicand
    reg [7:0]   count;                         // steps remaining (N <= 255)

    // combinational step
    reg  [N:0]     a_op;
    wire [2*N+1:0] shifted;
    always @* begin
        case ({q_reg[0], q_1})
            2'b01:   a_op = a_reg + m_reg;
            2'b10:   a_op = a_reg - m_reg;
            default: a_op = a_reg;
        endcase
    end
    // arithmetic shift right of {a_op, q_reg, q_1} by one position
    assign shifted = {a_op[N], a_op, q_reg, q_1} >> 1;

    always @(posedge clk) begin
        if (!rst_n) begin
            a_reg   <= {(N+1){1'b0}};
            q_reg   <= {N{1'b0}};
            q_1     <= 1'b0;
            m_reg   <= {(N+1){1'b0}};
            count   <= 8'd0;
            busy    <= 1'b0;
            done    <= 1'b0;
            product <= {(2*N){1'b0}};
        end else begin
            done <= 1'b0;
            if (!busy) begin
                if (start) begin
                    m_reg <= {multiplicand[N-1], multiplicand};
                    a_reg <= {(N+1){1'b0}};
                    q_reg <= multiplier;
                    q_1   <= 1'b0;
                    count <= N;
                    busy  <= 1'b1;
                end
            end else begin
                a_reg <= shifted[2*N+1:N+1];
                q_reg <= shifted[N:1];
                q_1   <= shifted[0];
                count <= count - 8'd1;
                if (count == 8'd1) begin
                    busy    <= 1'b0;
                    done    <= 1'b1;
                    product <= {shifted[2*N:N+1], shifted[N:1]};
                end
            end
        end
    end
endmodule
