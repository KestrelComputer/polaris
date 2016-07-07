`timescale 1ns / 1ps

// The memory stage of the CPU pipeline is responsible for communicating data
// loads and stores to the outside world.  Unlike the instruction fetch stage,
// slow devices attached to this bus WILL stall the pipeline, including
// instruction fetches.
//
// Note that the bus interface is not Wishbone bus compatible; it's up to an
// external bus bridge to provide the required logic to complete the Wishbone
// implementation.  The reason it's not a full Wishbone bus is to support
// misaligned transactions at some future date, as well as to support coupling
// with MMUs and caches, all of which need the higher-level data this bus
// provides.
//
// In particular, the following differences exist:
//
// M_CYC_O[3:0] -- instead of a single CYC_O bit, this CYC_O bus has four bits,
// giving the total size of the data transfer desired.  All four bits will be
// zero if no bus cycle is desired.  Otherwise:
//
// - CYC_O[3] will be set for a 64-bit transfer.  Data appears on DAT_IO[63:0].
// - CYC_O[2] will be set for a 32-bit transfer.  Data appears on DAT_IO[31:0].
// - CYC_O[1] will be set for a 16-bit transfer.  Data appears on DAT_IO[15:0].
// - CYC_O[0] will be set for an 8-bit transfer.  Data appears on DAT_IO[7:0].
//
// Theoretically, this mechanism allows for 24-bit transfers by setting both
// CYC_O[1] and CYC_O[0], meaning data would appear on DAT_IO[23:0].  However,
// this CPU never generates such bus transactions, since the only data types
// known are byte, half-word, word, and double-word.
//
// Wishbone's CYC_O and STB_O can be derived easily as |M_CYC_O (note leading
// pipe, telling Verilog to just OR-together the four cycle signals).
//
// M_DAT_I and M_DAT_O -- Instead of data appearing on different 8-bit lanes of
// the bus, byte data *always* appears on bits 7:0.  Similarly with half-word
// data appearing on bits 15:0, word data on 31:0, and double-word data on
// 63:0.
//
// The M-stage will sign-extend the results of a memory read depending on
// whether or not a Lx vs. LxU instruction is being executed.
//
// M_ADR_O -- the *full* 64-bit address, not just the uppermost address bits.
// M_ADR_O, M_CYC_O, and the bus steering logic needed to route data to the
// appropriate bits of M_DAT_IO all work together to allow external logic the
// *easy* ability to break a misaligned memory transaction into multiple
// aligned transactions on a real Wishbone bus.
//
// Wishbone SEL_O signals can be derived by looking at the lower ADR_O bits in
// conjunction with the appropriate CYC_O bits.

module stage_m(
	input	[3:0]	x_cyc_i,	// Memory cycle request from execute stage.
	input	[63:0]	x_alu_i,	// Result from ALU in execute stage.

	output	[3:0]	m_cyc_o,	// Similar to Wishbone MASTER cycle request.
	output	[63:0]	m_adr_o,	// Wishbone MASTER address bus.

	input		clk_i,		// Wishbone SYSCON clock.
	input		reset_i		// Wishbone SYSCON clock.
);
	reg m_cyc_o;
	always @(posedge clk_i) begin
		m_cyc_o <= (reset_i) ? 0 : x_cyc_i;
	end

	reg [63:0] m_adr_o;
	always @(posedge clk_i) begin
		m_adr_o <= x_alu_i;
	end
endmodule

// This module exercises the memory pipeline logic.

module test_stage_m();
	reg clk_o;		// Wishbone bus SYSCON clock.
	reg reset_o;		// Wishbone bus SYSCON reset.
	reg [15:0] story_o;	// Grep tag for when things go wrong.

	reg [3:0] x_cyc_o;	// 0, 1, 2, 4, or 8 only.
	reg [63:0] x_alu_o;	// Effective address from the ALU.

	wire [3:0] m_cyc_i;	// CYC_O coming from M stage.
	wire [63:0] m_adr_i;	// ADR_O coming from M stage.

	stage_m m(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.x_cyc_i(x_cyc_o),
		.x_alu_i(x_alu_o),
		.m_cyc_o(m_cyc_i),
		.m_adr_o(m_adr_i)
	);

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		wait(clk_o); wait(~clk_o);
	end
	endtask

	task assert_cycle;
	input [3:0] expected;
	begin
		if(m_cyc_i !== expected) begin
			$display("@E %04X Expected M_CYC_O=%d; got %d", story_o, expected, m_cyc_i);
			$stop;
		end
	end
	endtask

	task assert_address;
	input [63:0] expected;
	begin
		if(m_adr_i !== expected) begin
			$display("@E %04X Expected M_ADR_O=$%016X, got $%016X", story_o, expected, m_adr_i);
			$stop;
		end
	end
	endtask

	always begin
		#20 clk_o <= ~clk_o;
	end

	initial begin
		// During reset, regardless of whether or not a memory cycle
		// was in progress or not, we expect M_CYC_O to be negated.
		clk_o <= 0;
		x_cyc_o <= 1;
		reset_o <= 1;
		tick(16'h0000);
		assert_cycle(0);

		clk_o <= 0;
		x_cyc_o <= 2;
		reset_o <= 1;
		tick(16'h0010);
		assert_cycle(0);

		clk_o <= 0;
		x_cyc_o <= 4;
		reset_o <= 1;
		tick(16'h0020);
		assert_cycle(0);

		clk_o <= 0;
		x_cyc_o <= 8;
		reset_o <= 1;
		tick(16'h0030);
		assert_cycle(0);

		// After reset, M_CYC_O should remain negated (since X-stage
		// CYC_O should also be negated).
		x_cyc_o <= 0;
		reset_o <= 0;
		tick(16'h0100);
		assert_cycle(0);
		tick(16'h0101);
		assert_cycle(0);

		// M_CYC_O should be asserted when the execute stage is done
		// with an effective address calculation.
		x_cyc_o <= 1;
		tick(16'h0200);
		assert_cycle(1);

		x_cyc_o <= 2;
		tick(16'h0210);
		assert_cycle(2);

		x_cyc_o <= 4;
		tick(16'h0220);
		assert_cycle(4);

		x_cyc_o <= 8;
		tick(16'h0230);
		assert_cycle(8);

		// M_ADR_O should be the complete 64-bit result of the ALU.
		x_alu_o <= 64'h1122334455667788;
		tick(16'h0300);
		assert_address(64'h1122334455667788);
		assert_cycle(8);

		// If a memory cycle is not desired, then the ALU results
		// should be delivered directly to the writeback stage.

		$display("@I Done.");
		$stop;
	end
endmodule

