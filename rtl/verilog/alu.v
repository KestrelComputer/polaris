`timescale 1ns / 1ps

// The Arithmetic/Logic Unit (ALU) is responsible for performing the arithmetic
// and bitwise logical operations the computer depends upon to calculate
// everything from effective addresses for looking stuff up in memory, all the
// way to medical imaging.  (OK, the latter might have some help from floating
// point units later on, but I digress.)

module alu(
	input	[63:0]	inA_i,
	input	[63:0]	inB_i,
	output	[63:0]	out_o,
	output		cflag_o,
	output		vflag_o,
	output		zflag_o
);
	wire [63:0] sumL = inA_i[62:0] + inB_i[62:0];
	wire c62 = sumL[63];

	wire [64:63] sumH = inA_i[63] + inB_i[63] + c62;
	assign vflag_o = sumH[64] ^ sumL[63];
	assign cflag_o = sumH[64];
	assign out_o = {sumH[63], sumL[62:0]};
	assign zflag_o = ~(|out_o);
endmodule
