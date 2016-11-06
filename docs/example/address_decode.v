`timescale 1ns / 1ps

module address_decode(
	// Processor-side control
	input	iadr_i,
	input	istb_i,
	output	iack_o,

	// ROM-side control
	output	STB_o
);

	// For our example, we're just going to decode address bit A12.
	// If it's high, then we assume we're accessing ROM.
	// The ROM is asynchronous, so we just tie iack_o directly to the
	// the strobe pin.
	assign STB_o = iadr_i & istb_i;
	assign iack_o = STB_o;

	// We don't have any RAM resources to access, but if we did,
	// we would decode them here as well.
endmodule
