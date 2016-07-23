`timescale 1ns / 1ps

// The Arithmetic/Logic Unit (ALU) is responsible for performing the arithmetic
// and bitwise logical operations the computer depends upon to calculate
// everything from effective addresses for looking stuff up in memory, all the
// way to medical imaging.  (OK, the latter might have some help from floating
// point units later on, but I digress.)

module alu(
	input	[63:0]	inA_i,
	input	[63:0]	inB_i,
	output	[63:0]	out_o
);

	assign out_o = inA_i + inB_i;

endmodule
