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
	input	[3:0]	m_cyc_i,		// Memory cycle request from execute stage.
	input	[63:0]	m_alu_i,		// Result from ALU in execute stage.
	input	[4:0]	m_destination_i,	// Destination register specifier.

	input		m_store_i,		// 1 if processing a store instruction.
	output		m_we_o,			// 1 if writing to memory.
	input		m_unsigned_i,		// 1 if reading an unsigned value.
	input	[63:0]	m_wrdata_i,		// Data to write (if any)
	output	[4:0]	m_destination_o,	// Destination register specifier.
	output	[3:0]	m_cyc_o,		// Similar to Wishbone MASTER cycle request.
	output	[63:0]	m_adr_o,		// Wishbone MASTER address bus.
	input	[63:0]	m_dat_i,		// Wishbone MASTER data input from external memory.
	output	[63:0]	m_dat_o,		// Wishbone MASTER data output to external memory.
	input		m_ack_i,		// Wishbone MASTER acknowledge input.
	output		m_stall_o,		// True iff the pipeline should hold its current state.
	output	[63:0]	m_result_o,		// Result to writeback stage.

	input		clk_i,			// Wishbone SYSCON clock.
	input		reset_i			// Wishbone SYSCON clock.
);
	reg [3:0] m_cyc_o;
	reg [63:0] m_adr_o;
	reg [4:0] m_destination_o;
	reg m_we_o;
	reg [63:0] m_dat_o;
	reg m_stall_o;
	wire hold = ~m_ack_i & |m_cyc_o;
	always @(*) begin
		m_stall_o <= hold;
	end
	always @(posedge clk_i) begin
		if(m_stall_o) begin
			m_cyc_o <= (reset_i) ? 0 : m_cyc_o;
			m_adr_o <= m_adr_o;
			m_destination_o <= m_destination_o;
			m_we_o <= m_we_o;
			m_dat_o <= m_dat_o;
		end else begin
			m_cyc_o <= (reset_i) ? 0 : m_cyc_i;
			m_adr_o <= m_alu_i;
			m_destination_o <= m_destination_i;
			m_we_o <= m_store_i;
			m_dat_o <= m_wrdata_i;
		end
	end

	wire [63:0] unsigned_byte = {56'd0, m_dat_i[7:0]};
	wire [63:0] signed_byte = {{56{m_dat_i[7]}}, m_dat_i[7:0]};
	wire [63:0] unsigned_hword = {48'd0, m_dat_i[15:0]};
	wire [63:0] signed_hword = {{48{m_dat_i[15]}}, m_dat_i[15:0]};
	wire [63:0] unsigned_word = {32'd0, m_dat_i[31:0]};
	wire [63:0] signed_word = {{32{m_dat_i[31]}}, m_dat_i[31:0]};

	wire [63:0] data_from_memory =	(m_cyc_o[0] & m_unsigned_i) ? unsigned_byte :
					(m_cyc_o[0] & ~m_unsigned_i) ? signed_byte :
					(m_cyc_o[1] & m_unsigned_i) ? unsigned_hword :
					(m_cyc_o[1] & ~m_unsigned_i) ? signed_hword :
					(m_cyc_o[2] & m_unsigned_i) ? unsigned_word :
					(m_cyc_o[2] & ~m_unsigned_i) ? signed_word :
					m_dat_i;

	assign m_result_o = (|m_cyc_o) ? data_from_memory : m_adr_o;
endmodule

