`timescale 1ns / 1ps

`define PHASE 20	// 20ns per phase, 40ns per cycle, 25MHz

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
		$display("@S SCENARIO %0d (16'h%X)", story, story);
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

	// Exercise the CPU's behavior on cold reset.
	task test_bootstrap;
	begin
		clk_i <= 0;
		reset_i <= 0;
		iack_i <= 0;
		idat_i <= 32'h0000_0000;	// Guaranteed illegal instruction

		scenario(0);

//		$display("@D -TIME- CLK RST ISIZ IADR     IACK JAM ");
//		$monitor("@D %6d  %b   %b   %2b  %08X   %b   %b ", $time, clk_i, reset_i, isiz_o, iadr_o[31:0], iack_i, jammed_o);

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
		assert_jammed(0);
		tick(7);
		assert_isiz(2'b00);
		assert_jammed(1);

	end
	endtask

	// Exercise the CPU's ability to execute OP-I instructions.
	task test_op_i;
	begin
		scenario(1);

//		$display("@D -TIME- CLK ... ISIZ IADR     JAM ALUOUT  ");
//		$monitor("@D %6d  %b  ...  %2b  %08X  %b %016X : %08X : %d %d %016X %016X : %016X %016X", $time, clk_i, isiz_o, iadr_o[31:0], jammed_o, cpu.aluResult, cpu.ir, cpu.rwe_o, cpu.ra_mux, cpu.rdat_i, cpu.rdat_o, cpu.alua, cpu.alub);

		reset_i <= 1;
		tick(1);
		assert_isiz(2'b00);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 1;
		idat_i <= 32'h0000_0013;	// ADDI X0, X0, 0 (aka NOP)
		tick(3);
		assert_isiz(2'b00);
		assert_jammed(0);
		tick(4);
		assert_isiz(2'b00);
		assert_jammed(0);
		tick(5);
		assert_isiz(2'b00);
		assert_jammed(0);
		tick(6);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);
		assert_isiz(2'b10);
		assert_jammed(0);

		idat_i <= 32'h1240_0113;	// ADDI X2, X0, $124
		tick(7);
		assert_isiz(2'b00);
		tick(8);
		assert_isiz(2'b00);
		tick(9);
		assert_isiz(2'b00);
		tick(10);
		assert_isiz(2'b10);
		idat_i <= 32'h0001_0067;	// JALR X0, 0(X2)
		tick(11);
		tick(12);
		tick(13);
		tick(14);
		tick(15);
		assert_isiz(2'b10);
		assert_iadr(64'h0000_0000_0000_0124);
		idat_i <= 32'h1241_0113;	// @0124 ADDI X2, X2, $124
		tick(16);
		tick(17);
		tick(18);
		tick(19);
		assert_isiz(2'b10);
		idat_i <= 32'h0001_00E7;	// @0128 JALR X1, 0(X2)
		tick(20);			// X1 = $12C
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_isiz(2'b10);
		assert_iadr(64'h0000_0000_0000_0248);
		idat_i <= 32'hFFC0_8067;	// @0248 JALR X0, -4(X1)
		tick(25);
		tick(26);
		tick(27);
		tick(28);
		tick(29);
		assert_iadr(64'h0000_0000_0000_0128);
		assert_isiz(2'b10);
		idat_i <= 32'b000011111111_00010_111_00010_0010011;
		tick(30);			// X2 = $248
		tick(31);			// ANDI X2, X2, 255
		tick(32);
		tick(33);
		assert_iadr(64'h0000_0000_0000_012C);
		assert_isiz(2'b10);
		idat_i <= 32'b000000010000_00010_001_00010_0010011;
		tick(35);			// SLLI X2, X2, 16
		tick(36);
		tick(37);
		tick(38);
		assert_iadr(64'h0000_0000_0000_0130);
		assert_isiz(2'b10);
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(40);			// JALR X0, 0(X2)
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		assert_iadr(64'h0000_0000_0048_0000);
		assert_isiz(2'b10);
		// OP-IMM-32
		idat_i <= 32'b000000000001_00000_000_00011_0010011;
		tick(50);			// ADDI X3, X0, 1
		tick(51);
		tick(52);
		tick(53);
		idat_i <= 32'b000000011111_00011_001_00011_0011011;
		tick(55);			// SLLIW X3, X3, 31
		tick(56);
		tick(57);
		tick(58);
		idat_i <= 32'b000000000000_00011_000_00000_1100111;
		tick(60);			// JALR X0, 0(X3)
		tick(61);
		tick(62);
		tick(63);
		tick(64);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_8000_0000);
	end
	endtask

	// Exercise the CPU's ability to execute OP-R instructions.
	task test_op_r;
	begin
		scenario(2);

//		$display("@D -TIME- CLK ... ISIZ IADR     JAM ALUOUT  ");
//		$monitor("@D %6d  %b  ...  %2b  %08X  %b %016X : %08X : %d %d %016X %016X : %016X %016X", $time, clk_i, isiz_o, iadr_o[31:0], jammed_o, cpu.aluResult, cpu.ir, cpu.rwe_o, cpu.ra_mux, cpu.rdat_i, cpu.rdat_o, cpu.alua, cpu.alub);

		reset_i <= 1;
		tick(1);
		assert_isiz(2'b00);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 1;

		// We don't yet have loads implemented as I write this code,
		// so excrutiatingly tedious manual construction is required.
		// Please replace with cleaner code once design is bootstrapped.
		// ADDI X2, X0, -1
		idat_i <= 32'b111111111111_00000_000_00010_0010011;
		tick(0);
		tick(1);
		tick(2);
		tick(3);
		// ADDI X3, X0, $0AA
		idat_i <= 32'b000010101010_00000_000_00011_0010011;
		tick(5);
		tick(6);
		tick(7);
		tick(8);
		// ADDI X4, X0, $055
		idat_i <= 32'b000001010101_00000_000_00100_0010011;
		tick(10);
		tick(11);
		tick(12);
		tick(13);
		// SLLI X3, X3, 16
		idat_i <= 32'b000000010000_00011_001_00011_0010011;
		tick(15);
		tick(16);
		tick(17);
		tick(18);
		// XOR  X2, X2, X3
		idat_i <= 32'b0000000_00011_00010_100_00010_0110011;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF14);

		// SLLI X3, X3, 8
		idat_i <= 32'b000000001000_00011_001_00011_0010011;
		tick(25);
		tick(26);
		tick(27);
		tick(28);
		// XOR  X2, X2, X3
		idat_i <= 32'b0000000_00011_00010_100_00010_0110011;
		tick(30);
		tick(31);
		tick(32);
		tick(33);
		tick(34);
		// SLLI X4, X4, 32
		idat_i <= 32'b000000100000_00100_001_00100_0010011;
		tick(35);
		tick(36);
		tick(37);
		tick(38);
		// XOR  X2, X2, X4
		idat_i <= 32'b0000000_00100_00010_100_00010_0110011;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		// SLLI X4, X4, 8
		idat_i <= 32'b000000001000_00100_001_00100_0010011;
		tick(45);
		tick(46);
		tick(47);
		tick(48);
		// XOR  X2, X2, X4
		idat_i <= 32'b0000000_00100_00010_100_00010_0110011;
		tick(50);
		tick(51);
		tick(52);
		tick(53);
		tick(54);
		// JALR X0, 0(X2)
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(90);			// JALR X0, 0(X2)
		tick(91);
		tick(92);
		tick(93);
		tick(94);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_AAAA_5555_FFFF);
	end
	endtask

	// Exercise the CPU's ability to execute OP-R instructions.
	task test_lui_auipc;
	begin
		scenario(3);

//		$display("@D -TIME- CLK ... ISIZ IADR     JAM ALUOUT  ");
//		$monitor("@D %6d  %b  ...  %2b  %08X  %b %016X : %08X : %d %d %016X %016X : %016X %016X", $time, clk_i, isiz_o, iadr_o[31:0], jammed_o, cpu.aluResult, cpu.ir, cpu.rwe_o, cpu.ra_mux, cpu.rdat_i, cpu.rdat_o, cpu.alua, cpu.alub);

		reset_i <= 1;
		tick(1);
		assert_isiz(2'b00);
		reset_i <= 0;
		tick(2);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF00);
		assert_isiz(2'b10);
		assert_jammed(0);
		iack_i <= 1;


		// LUI X2, $DEADBEEF
		idat_i <= 32'b1101_1110_1010_1101_1011_00010_0110111;
		tick(10);
		tick(11);
		tick(12);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_FFFF_FF04);

		// JALR X0, 0(X2)
		idat_i <= 32'b000000000000_00010_000_00000_1100111;
		tick(20);
		tick(21);
		tick(22);
		tick(23);
		tick(24);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_DEAD_B000);

		// AUIPC X5, *+$524000
		idat_i <= 32'b0000_0000_0101_0010_0100_00101_0010111;
		tick(30);
		tick(31);
		tick(32);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_DEAD_B004);

		// JALR X0, 0(X5)
		idat_i <= 32'b000000000000_00101_000_00000_1100111;
		tick(40);
		tick(41);
		tick(42);
		tick(43);
		tick(44);
		assert_isiz(2'b10);
		assert_iadr(64'hFFFF_FFFF_DEFF_F000);
	end
	endtask

	initial begin
		test_bootstrap();
		test_op_i();
		test_op_r();
		test_lui_auipc();
		$display("@I Done."); $stop;
	end
endmodule

