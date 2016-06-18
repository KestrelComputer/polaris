`timescale 1ns / 1ps
`include "alu.vh"

// This module implements Polaris' Arithmetic and Logic Unit (ALU).  This is a
// purely combinatorial circuit; all logic is asynchronous.

module alu(
	input	[3:0]	operation_i,	// What should the ALU compute?
	input	[63:0]	in1_i,		// Operand 1
	input	[63:0]	in2_i,		// Operand 2
	output	[63:0]	result_o	// Final result
);
	reg [63:0] result_o;
	wire [5:0] shamt = in2_i[5:0];

	always @(*) begin
		case(operation_i)
		`ALU_ADD  : result_o <= in1_i + in2_i;
		`ALU_SUB  : result_o <= in1_i - in2_i;
		`ALU_SLT  : result_o <= {63'd0, ($signed(in1_i) < $signed(in2_i))};
		`ALU_SLTU : result_o <= {63'd0, ($unsigned(in1_i) < $unsigned(in2_i))};
		`ALU_XOR  : result_o <= in1_i ^ in2_i;
		`ALU_OR   : result_o <= in1_i | in2_i;
		`ALU_AND  : result_o <= in1_i & in2_i;
		`ALU_SLL  : result_o <= in1_i << shamt;
		`ALU_SRL  : result_o <= $unsigned(in1_i) >> shamt;
		`ALU_SRA  : result_o <= $signed(in1_i) >>> shamt;

		default: result_o <= 0;
		endcase
	end
endmodule

