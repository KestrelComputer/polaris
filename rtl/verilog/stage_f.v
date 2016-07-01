`timescale 1ns / 1ps

// This module implements the Polaris instruction fetch stage.  It's basically
// one half of the instruction Wishbone bus.  It is designed for asynchronous
// memories; if F_ACK_I is asserted in the same cycle as F_ADR_O and F_CYC_O
// are driven, then single-cycle instruction fetches are possible.
//
// The instruction fetch stage implements a 32-bit wide Wishbone bus, since all
// instructions are 32-bits wide.  Support for compressed instructions does not
// yet exist.  Similarly, support for 48-bit or wider instructions also does
// not yet exist, if they'll ever be.
//
// F_CYC_O asserted implies F_SEL_O and F_STB_O, which are not included in the
// port list.
//
// If F_ACK_I is negated during a cycle, this will introduce a bubble into the
// pipeline; however, it will not stall it.

`define RESET_PC	((64'hFFFF_FFFF_FFFF_FF00) >> 2)

module stage_f(
	input		clk_i,
	input		reset_i,

	// F-Bus (Instruction Fetch bus)
	output		f_cyc_o,	// Implies f_sel[3:0]
	input		f_ack_i,
	output	[63:2]	f_adr_o,
	input	[31:0]	f_dat_i
);
	reg f_cyc_o;
	always @(posedge clk_i) begin
		f_cyc_o <= ~reset_i;
	end

	wire f_ack = f_ack_i & f_cyc_o;
	wire [63:2] next_f_adr_o = (reset_i)? `RESET_PC : (f_ack)? f_adr_o + 1 : f_adr_o;

	reg [63:2] f_adr_o;		// Also known as Program Counter (PC).
	always @(posedge clk_i) begin
		f_adr_o <= next_f_adr_o;
	end
endmodule

