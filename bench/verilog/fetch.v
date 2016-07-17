`timescale 1ns / 1ps

// Exercise the instruction fetch module.

module test_fetch();
	reg [15:0] dat_o;
	reg [15:0] story_o;
	reg ack_o;
	reg clk_o;
	reg defined_o;
	reg pause_o;
	reg reset_o;
	reg [63:2] csr_mtvec_o;
	wire [1:0] size_i;
	wire [31:0] ir_i;
	wire [63:0] adr_i;
	wire mpie_mie_i;
	wire mie_0_i;
	wire mcause_2_i;

	fetch f(
		.ack_i(ack_o),
		.adr_o(adr_i),
		.clk_i(clk_o),
		.reset_i(reset_o),
		.size_o(size_i),
		.dat_i(dat_o),
		.defined_i(defined_o),
		.pause_i(pause_o),
		.ir_o(ir_i),
		.csr_mtvec_i(csr_mtvec_o),
		.mpie_mie_o(mpie_mie_i),
		.mie_0_o(mie_0_i),
		.mcause_2_o(mcause_2_i)
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		@(posedge clk_o); @(negedge clk_o);
	end
	endtask

	task assert_adr;
	input [63:0] expected;
	begin
		if(adr_i !== expected) begin
			$display("@E %04X ADR_O Expected=%016X Got=%016X", story_o, expected, adr_i);
			$stop;
		end
	end
	endtask

	task assert_ir;
	input [31:0] expected;
	begin
		if(ir_i !== expected) begin
			$display("@E %04X IR_I Expected=%08X Got=%08X", story_o, expected, ir_i);
			$stop;
		end
	end
	endtask

	task assert_size;
	input [1:0] expected;
	begin
		if(size_i !== expected) begin
			$display("@E %04X SIZE_O Expected=%d Got=%d", story_o, expected, size_i);
			$stop;
		end
	end
	endtask

	task assert_mpie_mie;
	input expected;
	begin
		if(mpie_mie_i !== expected) begin
			$display("@E %04X MPIE_MIE_O Expected=%d Got=%d", story_o, expected, mpie_mie_i);
			$stop;
		end
	end
	endtask

	task assert_mie_0;
	input expected;
	begin
		if(mie_0_i !== expected) begin
			$display("@E %04X MIE_0_O Expected=%d Got=%d", story_o, expected, mie_0_i);
			$stop;
		end
	end
	endtask

	task assert_mcause_2;
	input expected;
	begin
		if(mcause_2_i !== expected) begin
			$display("@E %04X MCAUSE_2_O Expected=%d Got=%d", story_o, expected, mcause_2_i);
			$stop;
		end
	end
	endtask

	initial begin
		clk_o <= 0;
		reset_o <= 0;
		ack_o <= 0;
		defined_o <= 1;
		pause_o <= 0;
		csr_mtvec_o <= 62'b01110111011101110111011101110111011101110111011101110111011101;
		tick(16'hFFFF);

		// When the CPU is reset, the bus must be idle.
		reset_o <= 1;
		tick(16'h0000);
		assert_size(0);
		tick(16'h0001);
		assert_size(0);

		// When the CPU comes out of reset, we expect the instruction
		// at $FFFFFFFFFFFFFF00 to be fetched.  This will take a total
		// of four clock cycles, assuming ACK_I is asserted the whole
		// time.

		reset_o <= 1;
		tick(16'h01FF);

		reset_o <= 0;
		ack_o <= 1;
		tick(16'h0100);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);

		dat_o <= 16'hAAAA;
		tick(16'h0101);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);

		tick(16'h0102);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);

		dat_o <= 16'hBBBB;
		tick(16'h0103);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);

		tick(16'h0110);
		assert_adr(64'hFFFFFFFFFFFFFF04);
		assert_ir(32'hBBBBAAAA);

		// When fetching an illegal instruction, the CPU must dispatch
		// to the illegal instruction trap handler.

		assert_mpie_mie(0);
		assert_mie_0(0);
		assert_mcause_2(0);
		defined_o <= 0;
		#1;	// Give the processor some time to notice the instruction is illegal.
		assert_mpie_mie(1);
		assert_mie_0(1);
		assert_mcause_2(1);
		tick(16'h0201);
		assert_adr(64'h7777777777777774);
		assert_mpie_mie(0);
		assert_mie_0(0);
		assert_mcause_2(0);
		dat_o <= 16'hCCCC;

		tick(16'h0202);
		tick(16'h0203);
		dat_o <= 16'hDDDD;

		tick(16'h0210);
		defined_o <= 1;
		#1;	// Give the processor some time to decode the "legal" instruction.
		assert_ir(32'hDDDDCCCC);
		assert_adr(64'h7777777777777778);

		// We expect the CPU to hold the state of the instruction fetch
		// if more wait-states are needed.

		reset_o <= 1;
		tick(16'h03FF);

		reset_o <= 0;
		ack_o <= 0;
		dat_o <= 16'hAAAA;
		tick(16'h0300);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);
		tick(16'h0301);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);
		tick(16'h0341);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);
		tick(16'h0381);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);
		tick(16'h03C1);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);
		ack_o <= 1;
		tick(16'h0302);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);
		ack_o <= 0;
		dat_o <= 16'hBBBB;
		tick(16'h0303);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);
		tick(16'h0343);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);
		tick(16'h0383);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);
		tick(16'h03C3);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);
		ack_o <= 1;

		tick(16'h0310);
		assert_adr(64'hFFFFFFFFFFFFFF04);
		assert_ir(32'hBBBBAAAA);
		$display("@DONE");
		$stop;
	end
endmodule

