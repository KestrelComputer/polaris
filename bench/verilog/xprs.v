`timescale 1ns / 1ps

// Exercise the Polaris integer register set, a 2-read-1-write bank of
// registers.

module test_xprs();
	reg clk_o;

	// Pretend we have a 100MHz clock.
	always begin
		#10 clk_o <= ~clk_o;
	end

	initial begin
		$display("World");
		$stop;
	end
endmodule

