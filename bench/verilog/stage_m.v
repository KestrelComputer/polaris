`timescale 1ns / 1ps

// The memory stage of the CPU pipeline is responsible for communicating data
// loads and stores to the outside world.  Unlike the instruction fetch stage,
// slow devices attached to this bus WILL stall the pipeline, including
// instruction fetches.

module stage_m(
	output		m_cyc_o,	// Wishbone MASTER cycle request.

	input		clk_i,		// Wishbone SYSCON clock.
	input		reset_i		// Wishbone SYSCON clock.
);
	reg m_cyc_o;
	always @(posedge clk_i) begin
		m_cyc_o <= 0;
	end
endmodule

// This module exercises the memory pipeline logic.

module test_stage_m();
	reg clk_o;		// Wishbone bus SYSCON clock.
	reg reset_o;		// Wishbone bus SYSCON reset.
	reg [15:0] story_o;	// Grep tag for when things go wrong.

	reg x_cyc_o;		// CYC_O signal from the execute stage.
	wire m_cyc_i;		// CYC_O coming from M stage.

	stage_m m(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.m_cyc_o(m_cyc_i)
	);

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		wait(clk_o); wait(~clk_o);
	end
	endtask

	task assert_cycle;
	input expected;
	begin
		if(m_cyc_i !== expected) begin
			$display("@E %04X Expected M_CYC_O=%d; got %d", story_o, expected, m_cyc_i);
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

		$display("@I Done.");
		$stop;
	end
endmodule

