// ALU opcode map shared by every ALU width, testbench and FPGA top.
// All eight 3-bit encodings are used, so there are no reserved opcodes.
`ifndef ALU_OPCODES_VH
`define ALU_OPCODES_VH
`define ALU_OP_ADD   3'b000   // y = a + b
`define ALU_OP_SUB   3'b001   // y = a - b
`define ALU_OP_AND   3'b010   // y = a & b
`define ALU_OP_OR    3'b011   // y = a | b
`define ALU_OP_XOR   3'b100   // y = a ^ b
`define ALU_OP_XNOR  3'b101   // y = ~(a ^ b)
`define ALU_OP_NOTA  3'b110   // y = ~a
`define ALU_OP_PASSB 3'b111   // y = b
`endif
