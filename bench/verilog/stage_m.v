`timescale 1ns / 1ps

// This module exercises the memory pipeline logic.

module test_stage_m();
	reg clk_o;			// Wishbone bus SYSCON clock.
	reg reset_o;			// Wishbone bus SYSCON reset.
	reg [15:0] story_o;		// Grep tag for when things go wrong.

	reg [3:0] m_cyc_o;		// 0, 1, 2, 4, or 8 only.
	reg [63:0] m_alu_o;		// Effective address from the ALU.

	wire [3:0] m_cyc_i;		// CYC_O coming from M stage.
	wire [63:0] m_adr_i;		// ADR_O coming from M stage.
	wire [63:0] m_result_i;		// ALU result or data input, depending on M_CYC_O.
	reg [63:0] m_dat_o;		// 64-bit input data bus driver.
	reg [4:0] m_destination_o;	// Destination register specifier.
	wire [4:0] m_destination_i;
	reg m_unsigned_o;		// True if unsigned read in progress.
	reg m_store_o;			// True if executing a store instruction.
	wire m_we_i;
	reg [63:0] m_wrdata_o;		// The data to write to memory, from execute stage.
	wire [63:0] m_dat_i;		// Wishbone bus MASTER write data.
	reg m_ack_o;			// Wishbone bus MASTER acknowledgement input.
	wire m_stall_i;			// True iff the pipeline should be stalled.

	stage_m m(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.m_cyc_i(m_cyc_o),
		.m_alu_i(m_alu_o),
		.m_stall_o(m_stall_i),
		.m_destination_i(m_destination_o),
		.m_wrdata_i(m_wrdata_o),
		.m_dat_o(m_dat_i),
		.m_we_o(m_we_i),
		.m_ack_i(m_ack_o),
		.m_store_i(m_store_o),
		.m_unsigned_i(m_unsigned_o),
		.m_destination_o(m_destination_i),
		.m_dat_i(m_dat_o),
		.m_result_o(m_result_i),
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

	task assert_destination;
	input [4:0] expected;
	begin
		if(m_destination_i !== expected) begin
			$display("@E %04X Expected M_DESTINATION_O=%d; got %d", story_o, expected, m_destination_i);
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

	task assert_result;
	input [63:0] expected;
	begin
		if(m_result_i !== expected) begin
			$display("@E %04X Expected M_RESULT_O=$%016X, got $%016X", story_o, expected, m_result_i);
			$stop;
		end
	end
	endtask

	task assert_write;
	input expected;
	begin
		if(m_we_i !== expected) begin
			$display("@E %04X Expected M_WE_O=%d, got %d", story_o, expected, m_we_i);
			$stop;
		end
	end
	endtask

	task assert_written;
	input [63:0] expected;
	begin
		if(m_dat_i !== expected) begin
			$display("@E %04X Expected M_DAT_O=$%016X, got $%016X", story_o, expected, m_dat_i);
			$stop;
		end
	end
	endtask

	task assert_stall;
	input expected;
	begin
		if(m_stall_i !== expected) begin
			$display("@E %04X Expected M_STALL_O=%d, got %d", story_o, expected, m_stall_i);
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
		m_ack_o <= 1;
		m_cyc_o <= 1;
		reset_o <= 1;
		tick(16'h0000);
		assert_cycle(0);

		m_cyc_o <= 2;
		reset_o <= 1;
		tick(16'h0010);
		assert_cycle(0);

		m_cyc_o <= 4;
		reset_o <= 1;
		tick(16'h0020);
		assert_cycle(0);

		m_cyc_o <= 8;
		reset_o <= 1;
		tick(16'h0030);
		assert_cycle(0);

		// After reset, M_CYC_O should remain negated (since X-stage
		// CYC_O should also be negated).
		m_cyc_o <= 0;
		reset_o <= 0;
		tick(16'h0100);
		assert_cycle(0);
		tick(16'h0101);
		assert_cycle(0);

		// M_CYC_O should be asserted when the execute stage is done
		// with an effective address calculation.
		m_cyc_o <= 1;
		tick(16'h0200);
		assert_cycle(1);

		m_cyc_o <= 2;
		tick(16'h0210);
		assert_cycle(2);

		m_cyc_o <= 4;
		tick(16'h0220);
		assert_cycle(4);

		m_cyc_o <= 8;
		tick(16'h0230);
		assert_cycle(8);

		// M_ADR_O should be the complete 64-bit result of the ALU.
		m_alu_o <= 64'h1122334455667788;
		tick(16'h0300);
		assert_address(64'h1122334455667788);
		assert_cycle(8);

		// If a memory cycle is not desired, then the ALU results
		// should be delivered directly to the writeback stage.
		// While we're at it, we make sure the writeback destination
		// matches that supplied by the execute stage.
		m_cyc_o <= 0;
		m_dat_o <= 64'h99AABBCCDDEEFF00;
		m_destination_o <= 4;
		tick(16'h0400);
		assert_address(64'h1122334455667788);
		assert_result(64'h1122334455667788);
		assert_destination(4);

		// If a memory cycle is desired, however, the ALU results
		// should only drive the address bus.  Any data present on the
		// input data bus should be the result stored to the register
		// file.
		m_cyc_o <= 8;
		tick(16'h0410);
		assert_address(64'h1122334455667788);
		assert_result(64'h99AABBCCDDEEFF00);

		// When reading, 8-bit values should be signed or unsigned
		// depending on which load instruction is being executed.
		// Unsigned values are zero-extended.
		m_cyc_o <= 1;
		m_dat_o <= 64'h40;
		m_unsigned_o <= 0;
		tick(16'h0500);
		assert_result(64'h0000_0000_0000_0040);

		m_dat_o <= 64'h80;
		tick(16'h0510);
		assert_result(64'hFFFF_FFFF_FFFF_FF80);

		m_unsigned_o <= 1;
		tick(16'h0520);
		assert_result(64'h0000_0000_0000_0080);

		// When reading, 16-bit values should be signed or unsigned
		// depending on which load instruction is being executed.
		// Unsigned values are zero-extended.
		m_cyc_o <= 2;
		m_dat_o <= 64'h4000;
		m_unsigned_o <= 0;
		tick(16'h0600);
		assert_result(64'h0000_0000_0000_4000);

		m_dat_o <= 64'h8000;
		tick(16'h0610);
		assert_result(64'hFFFF_FFFF_FFFF_8000);

		m_unsigned_o <= 1;
		tick(16'h0620);
		assert_result(64'h0000_0000_0000_8000);


		// When reading, 32-bit values should be signed or unsigned
		// depending on which load instruction is being executed.
		// Unsigned values are zero-extended.
		m_cyc_o <= 4;
		m_dat_o <= 64'h40000000;
		m_unsigned_o <= 0;
		tick(16'h0700);
		assert_result(64'h0000_0000_4000_0000);

		m_dat_o <= 64'h80000000;
		tick(16'h0710);
		assert_result(64'hFFFF_FFFF_8000_0000);

		m_unsigned_o <= 1;
		tick(16'h0720);
		assert_result(64'h0000_0000_8000_0000);

		// When storing, the write-enable signal should be asserted.
		m_store_o <= 1;
		tick(16'h0800);
		assert_write(1);

		m_store_o <= 0;
		tick(16'h0810);
		assert_write(0);

		// When storing, the data presented on m_dat_o must be equal to
		// the value appearing on m_wrdata_i.
		m_wrdata_o <= 64'h0011223344556677;
		m_store_o <= 1;
		m_cyc_o <= 4;
		m_dat_o <= 64'h8899AABBCCDDEEFF;
		m_unsigned_o <= 0;
		tick(16'h0900);
		assert_written(64'h0011223344556677);
		assert_result(64'hFFFFFFFFCCDDEEFF);

		// When a cycle is not acknowledged, the entire pipeline must
		// stall.  This necessarily includes instruction fetch, of
		// course.
		m_cyc_o <= 1;
		m_ack_o <= 1;
		m_alu_o <= 64'h0011223344556677;
		m_destination_o <= 14;
		tick(16'h0A00);
		assert_stall(0);
		assert_address(64'h0011223344556677);
		assert_result(64'hFFFFFFFFFFFFFFFF);
		assert_destination(14);

		m_ack_o <= 0;
		m_alu_o <= 64'h8899AABBCCDDEEFF;
		m_destination_o <= 31;
		tick(16'h0A10);
		assert_stall(1);
		assert_address(64'h0011223344556677);
		assert_result(64'hFFFFFFFFFFFFFFFF);
		assert_destination(14);

		// When a cycle is not required, the acknowledge pin should be
		// ignored.
		m_cyc_o <= 0;
		m_ack_o <= 1;
		tick(16'h0B00);
		assert_stall(0);

		m_ack_o <= 0;
		tick(16'h0B10);
		assert_stall(0);

		$display("@I Done.");
		$stop;
	end
endmodule

