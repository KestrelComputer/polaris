`timescale 1ns / 1ps

// The Arithmetic/Logic Unit (ALU) is responsible for performing the arithmetic
// and bitwise logical operations the computer depends upon to calculate
// everything from effective addresses for looking stuff up in memory, all the
// way to medical imaging.  (OK, the latter might have some help from floating
// point units later on, but I digress.)

module alu(
);

endmodule

// This module verifies correct register file behavior.

module test_alu();
	reg clk_o;
	reg reset_o;
	reg [15:0] story_o;

	alu a(
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		@(posedge clk_o);
		@(negedge clk_o);
	end
	endtask

	initial begin
		clk_o <= 0;

		$display("@DONE");
		$stop;
	end
endmodule
