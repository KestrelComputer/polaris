`timescale 1ns / 1ps

`define PHASE 20	// 20ns per phase, 40ns per cycle, 25MHz

module PolarisCPU(
	// MISC DIAGNOSTICS

	output			jammed_o,

	// I MASTER

	input			iack_i,
	input	[31:0]		idat_i,
	output	[63:0]		iadr_o,
	output	[1:0]		isiz_o,

	// SYSCON

	input			clk_i,
	input			reset_i
);
	// Sequencer outputs
	wire		pc_mbvec, pc_pcPlus4;
	wire		ft0_o;
	wire		iadr_pc;
	wire		isiz_2;

	// Sequencer inputs
	reg		ft0;

	// Internal working wires and registers
	reg		rst;
	reg	[63:0]	pc;
	wire	[63:0]	pc_mux;

	assign isiz_o = isiz_2 ? 2'b10 : 2'b00;
	wire pc_pc    = ~|{pc_mbvec,pc_pcPlus4};
	assign pc_mux = (pc_mbvec ? 64'hFFFF_FFFF_FFFF_FF00 : 64'h0) |
			(pc_pcPlus4 ? pc + 4 : 64'h0) |
			(pc_pc ? pc : 64'h0);	// base case
	assign iadr_o = iadr_pc ? pc : 0;

	always @(posedge clk_i) begin
		rst <= reset_i;
		pc <= pc_mux;
		ft0 <= ft0_o;
	end

	Sequencer s(
		.jammed_o(jammed_o),
		.ft0(ft0),
		.isiz_2(isiz_2),
		.iadr_pc(iadr_pc),
		.iack_i(iack_i),
		.pc_mbvec(pc_mbvec),
		.pc_pcPlus4(pc_pcPlus4),
		.ft0_o(ft0_o),
		.rst(rst)
	);
endmodule

module PolarisCPU_tb();
	reg	[31:0]	story_o;
	reg		clk_i;
	reg		reset_i;

	reg		iack_i;
	reg	[31:0]	idat_i;
	wire	[63:0]	iadr_o;
	wire	[1:0]	isiz_o;
	wire		jammed_o;

	task scenario;		// Pointless task helps with searching in text editor.
	input [15:0] story;
	begin
		story_o <= {story, 16'h0000};
		@(clk_i);
		@(~clk_i);
		#(`PHASE/2);
	end
	endtask

	task tick;
	input [15:0] story;
	begin
		story_o <= {story_o[31:16], story};
		#(`PHASE * 2);
	end
	endtask

	task assert_iadr;
	input [63:0] expected;
	begin
		if(iadr_o !== expected) begin
		$display("@E %08X IADR_O Expected=%016X Got=%016X", story_o, expected, iadr_o);
		$stop;
		end
	end
	endtask

	task assert_isiz;
	input [1:0] expected;
	begin
		if(isiz_o !== expected) begin
		$display("@E %08X ISIZ_O Expected=%x Got=%x", story_o, expected, isiz_o);
		$stop;
		end
	end
	endtask

	task assert_jammed;
	input expected;
	begin
		if(jammed_o !== expected) begin
		$display("@E %08X JAMMED_O Expected=%b Got=%b", story_o, expected, jammed_o);
		$stop;
		end
	end
	endtask

	always begin
		#`PHASE clk_i <= ~clk_i;
	end

	PolarisCPU cpu(
		// Miscellaneous Diagnostics

		.jammed_o(jammed_o),

		// I MASTER

		.iack_i(iack_i),
		.idat_i(idat_i),
		.iadr_o(iadr_o),
		.isiz_o(isiz_o),

		// SYSCON

		.clk_i(clk_i),
		.reset_i(reset_i)
	);

	initial begin
		$display("@D -TIME- CLK RST ISIZ IADR     JAM ");
		$monitor("@D %6d  %b   %b   %2b  %08X  %b ", $time, clk_i, reset_i, isiz_o, iadr_o[31:0], jammed_o);

		clk_i <= 0;
		reset_i <= 0;
		iack_i <= 0;
		
		scenario(0);

		reset_i <= 1;
		tick(1);
		assert_isiz(2'b00);
		tick(2);
		assert_isiz(2'b00);
		reset_i <= 0;
		tick(3);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 0;
		tick(4);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 0;
		tick(5);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 1;
		tick(6);
		assert_isiz(2'b00);
		assert_jammed(1);

		$display("@I Done."); $stop;
	end
endmodule

