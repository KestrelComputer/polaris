`timescale 1ns / 1ps

// This module verifies correct register file behavior.

module test_alu();
	reg clk_o;
	reg reset_o;
	reg [15:0] story_o;
	reg [63:0] inA_o, inB_o;
	wire [63:0] out_i;

	alu a(
		.inA_i(inA_o),
		.inB_i(inB_o),
		.out_o(out_i)
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

	task assert_out;
	input [63:0] expected;
	begin
		if(expected !== out_i) begin
			$display("@E %04X OUT_O Expected $%016X, got $%016X", story_o, expected, out_i);
			$stop;
		end
	end
	endtask

	task check_sum_bit;
	input [15:0] story;
	input [63:0] base;
	begin
		inA_o <= base;
		inB_o <= base;
		tick(story);
		assert_out({base[62:0], 1'b0});
	end
	endtask

	initial begin
		clk_o <= 0;

		// We expect the ALU to add two 64-bit numbers.

		check_sum_bit(16'h0000, 64'h0000_0000_0000_0001);
		check_sum_bit(16'h0001, 64'h0000_0000_0000_0002);
		check_sum_bit(16'h0002, 64'h0000_0000_0000_0004);
		check_sum_bit(16'h0003, 64'h0000_0000_0000_0008);

		check_sum_bit(16'h0004, 64'h0000_0000_0000_0010);
		check_sum_bit(16'h0005, 64'h0000_0000_0000_0020);
		check_sum_bit(16'h0006, 64'h0000_0000_0000_0040);
		check_sum_bit(16'h0007, 64'h0000_0000_0000_0080);

		check_sum_bit(16'h0008, 64'h0000_0000_0000_0100);
		check_sum_bit(16'h0009, 64'h0000_0000_0000_0200);
		check_sum_bit(16'h000A, 64'h0000_0000_0000_0400);
		check_sum_bit(16'h000B, 64'h0000_0000_0000_0800);

		check_sum_bit(16'h000C, 64'h0000_0000_0000_1000);
		check_sum_bit(16'h000D, 64'h0000_0000_0000_2000);
		check_sum_bit(16'h000E, 64'h0000_0000_0000_4000);
		check_sum_bit(16'h000F, 64'h0000_0000_0000_8000);

		check_sum_bit(16'h0010, 64'h0000_0000_0001_0000);
		check_sum_bit(16'h0011, 64'h0000_0000_0002_0000);
		check_sum_bit(16'h0012, 64'h0000_0000_0004_0000);
		check_sum_bit(16'h0013, 64'h0000_0000_0008_0000);

		check_sum_bit(16'h0014, 64'h0000_0000_0010_0000);
		check_sum_bit(16'h0015, 64'h0000_0000_0020_0000);
		check_sum_bit(16'h0016, 64'h0000_0000_0040_0000);
		check_sum_bit(16'h0017, 64'h0000_0000_0080_0000);

		check_sum_bit(16'h0018, 64'h0000_0000_0100_0000);
		check_sum_bit(16'h0019, 64'h0000_0000_0200_0000);
		check_sum_bit(16'h001A, 64'h0000_0000_0400_0000);
		check_sum_bit(16'h001B, 64'h0000_0000_0800_0000);

		check_sum_bit(16'h001C, 64'h0000_0000_1000_0000);
		check_sum_bit(16'h001D, 64'h0000_0000_2000_0000);
		check_sum_bit(16'h001E, 64'h0000_0000_4000_0000);
		check_sum_bit(16'h001F, 64'h0000_0000_8000_0000);

		check_sum_bit(16'h0020, 64'h0000_0001_0000_0000);
		check_sum_bit(16'h0021, 64'h0000_0002_0000_0000);
		check_sum_bit(16'h0022, 64'h0000_0004_0000_0000);
		check_sum_bit(16'h0023, 64'h0000_0008_0000_0000);

		check_sum_bit(16'h0024, 64'h0000_0010_0000_0000);
		check_sum_bit(16'h0025, 64'h0000_0020_0000_0000);
		check_sum_bit(16'h0026, 64'h0000_0040_0000_0000);
		check_sum_bit(16'h0027, 64'h0000_0080_0000_0000);

		check_sum_bit(16'h0028, 64'h0000_0100_0000_0000);
		check_sum_bit(16'h0029, 64'h0000_0200_0000_0000);
		check_sum_bit(16'h002A, 64'h0000_0400_0000_0000);
		check_sum_bit(16'h002B, 64'h0000_0800_0000_0000);

		check_sum_bit(16'h002C, 64'h0000_1000_0000_0000);
		check_sum_bit(16'h002D, 64'h0000_2000_0000_0000);
		check_sum_bit(16'h002E, 64'h0000_4000_0000_0000);
		check_sum_bit(16'h002F, 64'h0000_8000_0000_0000);

		check_sum_bit(16'h0030, 64'h0001_0000_0000_0000);
		check_sum_bit(16'h0031, 64'h0002_0000_0000_0000);
		check_sum_bit(16'h0032, 64'h0004_0000_0000_0000);
		check_sum_bit(16'h0033, 64'h0008_0000_0000_0000);

		check_sum_bit(16'h0034, 64'h0010_0000_0000_0000);
		check_sum_bit(16'h0035, 64'h0020_0000_0000_0000);
		check_sum_bit(16'h0036, 64'h0040_0000_0000_0000);
		check_sum_bit(16'h0037, 64'h0080_0000_0000_0000);

		check_sum_bit(16'h0038, 64'h0100_0000_0000_0000);
		check_sum_bit(16'h0039, 64'h0200_0000_0000_0000);
		check_sum_bit(16'h003A, 64'h0400_0000_0000_0000);
		check_sum_bit(16'h003B, 64'h0800_0000_0000_0000);

		check_sum_bit(16'h003C, 64'h1000_0000_0000_0000);
		check_sum_bit(16'h003D, 64'h2000_0000_0000_0000);
		check_sum_bit(16'h003E, 64'h4000_0000_0000_0000);
		check_sum_bit(16'h003F, 64'h8000_0000_0000_0000);

		$display("@DONE");
		$stop;
	end
endmodule
