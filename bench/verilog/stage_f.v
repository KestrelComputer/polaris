`timescale 1ns / 1ps

// This module exercises the instruction fetch functionality, as viewed by an
// external memory subsystem.

module test_stage_f();
	reg [15:0] story_o;
	reg clk_o;
	reg reset_o;

	wire f_cyc_i;
	wire [63:2] f_adr_i;
	reg f_ack_o;

	wire m_cyc_i;

	stage_f f(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.f_cyc_o(f_cyc_i),
		.f_ack_i(f_ack_o),
		.f_adr_o(f_adr_i)
	);

	// 50MHz clock.
	always begin
		#20 clk_o <= ~clk_o;
	end

	task assert_f_bus_idle;
	begin
		if(f_cyc_i !== 0) begin
			$display("@E %04X Expected F-bus to be idle.", story_o);
			$stop;
		end
	end
	endtask

	task assert_f_bus_cycle;
	begin
		if(f_cyc_i !== 1) begin
			$display("@E %04X Expected F-bus to be in a cycle.", story_o);
			$stop;
		end
	end
	endtask

	task assert_f_adr;
	input [63:0] expected_address;
	begin
		if(f_adr_i !== expected_address[63:2]) begin
			$display("@E %04X Expected instruction fetch from $%016X; got $%016X", story_o, expected_address, {f_adr_i, 2'b00});
			$stop;
		end
	end
	endtask

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		wait(clk_o); wait(~clk_o);
	end
	endtask

	initial begin
		clk_o <= 0;
		reset_o <= 0;
		f_ack_o <= 1;
		tick(16'hFFFF);

		// The instruction and data buses should be idle upon reset.
		reset_o <= 1;
		tick(16'h0000);
		assert_f_bus_idle();

		// After reset, Polaris must fetch its first instruction from $FFFF_FFFF_FFFF_FF00.
		reset_o <= 0;
		tick(16'h0100);
		assert_f_bus_cycle();
		assert_f_adr(64'hFFFF_FFFF_FFFF_FF00);

		// Instruction fetch MUST wait for slow memory.
		tick(16'h0200);
		assert_f_bus_cycle();
		assert_f_adr(64'hFFFF_FFFF_FFFF_FF04);
		f_ack_o <= 0;
		tick(16'h0210);
		assert_f_bus_cycle();
		assert_f_adr(64'hFFFF_FFFF_FFFF_FF04);
		tick(16'h0220);
		assert_f_bus_cycle();
		assert_f_adr(64'hFFFF_FFFF_FFFF_FF04);
		f_ack_o <= 1;
		tick(16'h0230);
		assert_f_bus_cycle();
		assert_f_adr(64'hFFFF_FFFF_FFFF_FF08);
		
		$display("@I Done.");
		$stop;
	end
endmodule
