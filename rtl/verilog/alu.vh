`ifndef POLARIS_ALU_VH
`define POLARIS_ALU_VH

// Bits come from bit 30 and bits 14..12 of an instruction.
//
// 			   3111
//			   0432
//			   ||||
`define ALU_ADD		4'b0000
`define ALU_SLL		4'b0001
`define ALU_SLT		4'b0010
`define ALU_SLTU	4'b0011
`define ALU_XOR		4'b0100
`define ALU_SRL		4'b0101
`define ALU_OR		4'b0110
`define ALU_AND		4'b0111
`define ALU_SUB		4'b1000
`define ALU_illegal9	4'b1001
`define ALU_illegalA	4'b1010
`define ALU_illegalB	4'b1011
`define ALU_illegalC	4'b1100
`define ALU_SRA		4'b1101
`define ALU_illegalE	4'b1110
`define ALU_illegalF	4'b1111

`endif

