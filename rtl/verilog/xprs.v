`timescale 1ns / 1ps

// This module implements the RISC-V integer register set.
//
// Note: This register set implements two read ports and one write
// port.  The read ports are ASYNCHRONOUS.  The write port is
// SYNCHRONOUS.

module xprs(
	input		clk_i,	// CPU clock
	input		we_i,	// 1 to enable register write on next clk_i.
	input	[4:0]	rd_i,	// Destination register address
	input	[4:0]	rs1_i,	// Source register address (1)
	input	[4:0]	rs2_i,	// Source register address (2)
	input	[63:0]	d_i,	// Input data for destination register
	output	[63:0]	q1_o,	// Output for register 1
	output	[63:0]	q2_o	// Output for register 2
);
	assign q1_o = (|rs1_i) ? register_file[rs1_i] : 0;
	assign q2_o = (|rs2_i) ? register_file[rs2_i] : 0;

	reg [63:0] register_file[0:31];

	always @(posedge clk_i) begin
		if(we_i) begin
			register_file[rd_i] <= d_i;
		end
	end
endmodule

