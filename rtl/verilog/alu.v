`timescale 1ns / 1ps

// The Arithmetic/Logic Unit (ALU) is responsible for performing the arithmetic
// and bitwise logical operations the computer depends upon to calculate
// everything from effective addresses for looking stuff up in memory, all the
// way to medical imaging.  (OK, the latter might have some help from floating
// point units later on, but I digress.)

module alu(
	input	[63:0]	inA_i,
	input	[63:0]	inB_i,
	input		cflag_i,
	input		sum_en_i,
	input		and_en_i,
	output	[63:0]	out_o,
	output		cflag_o,
	output		vflag_o,
	output		zflag_o
);
	wire [63:0] sumL = inA_i[62:0] + inB_i[62:0] + cflag_i;
	wire c62 = sumL[63];

	wire [64:63] sumH = inA_i[63] + inB_i[63] + c62;
	assign vflag_o = sumH[64] ^ sumL[63];
	assign cflag_o = sumH[64];

	wire [63:0] sums = sum_en_i ? {sumH[63], sumL[62:0]} : 64'd0;
	assign zflag_o = ~(|out_o);

	wire [63:0] ands = and_en_i ? {inA_i & inB_i} : 64'd0;

	assign out_o = sums | ands;
endmodule
