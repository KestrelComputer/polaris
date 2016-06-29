`timescale 1ns / 1ps
`include "rtl/verilog/alu.vh"

// This module implements the instruction decoder stage of the Polaris pipeline.
//
// It's possible to accept one instruction every clock cycle.  If for some reason this is not possible, F_ACK_I
// will be negated.  This will not halt the pipeline's progress; rather, it will cause a "bubble" to be introduced into the pipeline.
// Bubbles are always decoded as ADDI X0, X0, 0 instructions, which means they're equivalent to NOP instructions.

module stage_d(
	input		clk_i,
	input		reset_i,

	// F-stage I/O
	input		f_ack_i,	// Instruction valid signal, basically.
	input	[31:0]	f_dat_i,	// Next Instruction

	// D-stage I/O
	output	[63:0]	d_vs1_o,	// Contents of 1st operand (register or immediate as appropriate)
	output	[63:0]	d_vs2_o,	// Contents of 2nd operand (register or immediate as appropriate)
	output	[4:0]	d_rd_o,		// Destination register for eventual write-back, or 0.
	output	[3:0]	d_alu_o,	// ALU operation.  If none, ADD if usually a safe default.
	output		d_mem_o,	// This instruction touches memory if asserted.

	// W-stage I/O
	input	[63:0]	w_dat1_i,	// Contents of register 1 from register file (W for writeback stage)
	output	[4:0]	w_rs1_o
);
	wire isBubble = reset_i | ~f_ack_i;

	reg [31:0] ir;		// Instruction register
	always @(posedge clk_i) begin
		ir <= (isBubble) ? 32'h00000013 : f_dat_i;
	end

	// Break out the various instruction fields.  Note that some fields may
	// overlap.

	wire [6:0] opcode = ir[6:0];
	assign d_rd_o = ir[11:7];
	wire [2:0] fn3 = ir[14:12];
	assign w_rs1_o = ir[19:15];
	wire fn4sign = ~is_aluI ? ir[30] : isShift ? ir[30] : 0;
	wire [3:0] d_alu_o = {fn4sign, fn3};

	// These are all the different kinds of immediate operands RISC-V supports.
	wire [63:0] imm12i = {{52{ir[31]}}, ir[31:20]};		// 12-bit signed (I, non-shifts)
	wire [63:0] imm6sh = {58'd0, ir[25:20]};		// 6-bit unsigned (I, shifts)

	
	// Steer data to the first ALU input for the execute stage.

	assign d_vs1_o = (isBubble)? 64'h0000000000000000 : w_dat1_i;

	// Steer data to the second ALU input for the execute stage.

	wire is_aluI = opcode == 7'b0010011;
	wire isShift = (fn3 == 3'b001) | (fn3 == 3'b101);
	wire d_mem_o = 0;

	assign d_vs2_o = (is_aluI & ~isShift)? imm12i : (is_aluI & isShift) ? imm6sh : imm12i;
endmodule

// This module exercises the instruction decode functionality, as viewed by both the instruction fetch logic and the execute logic.

module test_stage_d();
	reg [15:0] story_o;
	reg clk_o;
	reg reset_o;

	reg f_ack_o;
	reg [31:0] f_dat_o;

	wire [4:0] rd_i;		// Destination register (X0..X31)
	wire [4:0] rs1_i;		// Source register 1 (normally goes to register file)
	reg [63:0] w_dat1_o;		// Register file's concept of register 1's value.
	wire [63:0] vs1_i;		// Contents of register Rs1 or immediate, as appropriate
	wire [63:0] vs2_i;		// Contents of register Rs2 or immediate, as appropriate
	wire [3:0] d_alu_i;
	wire d_mem_i;

	stage_d d(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.f_ack_i(f_ack_o),
		.f_dat_i(f_dat_o),
		.d_rd_o(rd_i),
		.w_rs1_o(rs1_i),
		.w_dat1_i(w_dat1_o),
		.d_vs1_o(vs1_i),
		.d_vs2_o(vs2_i),
		.d_alu_o(d_alu_i),
		.d_mem_o(d_mem_i)
	);

	// 50MHz clock.
	always begin
		#20 clk_o <= ~clk_o;
	end

	task assert_bubble;
	begin
		assert_rd(0);
		assert_rs1(0);
		assert_vs1(0);
		assert_vs2(0);
		assert_alu_fn(`ALU_ADD);
	end
	endtask

	task assert_rs1;
	input [4:0] expected;
	begin
		if(rs1_i !== expected) begin
			$display("@E %04X Expected Rs1=$%016X; got Rs1=%016X", story_o, expected, rs1_i);
			$stop;
		end
	end
	endtask

	task assert_rd;
	input [4:0] expected;
	begin
		if(rd_i !== expected) begin
			$display("@E %04X Expected Rd=$%016X; got Rd=%016X", story_o, expected, rd_i);
			$stop;
		end
	end
	endtask

	task assert_vs1;
	input [63:0] expected;
	begin
		if(vs1_i !== expected) begin
			$display("@E %04X Expected Vs1=$%016X; got Vs1=%016X", story_o, expected, vs1_i);
			$stop;
		end
	end
	endtask

	task assert_vs2;
	input [63:0] expected;
	begin
		if(vs2_i !== expected) begin
			$display("@E %04X Expected Vs2=$%016X; got Vs2=%016X", story_o, expected, vs2_i);
			$stop;
		end
	end
	endtask

	task assert_alu_fn;
	input [3:0] expected;
	begin
		if(d_alu_i !== expected) begin
			$display("@E %04X Expected ALU code %d; got %d.", story_o, expected, d_alu_i);
			$stop;
		end
	end
	endtask

	task assert_mem;
	input expected;
	begin
		if(d_mem_i !== expected) begin
			$display("@E %04X Expected mem %d; got %d.", story_o, expected, d_mem_i);
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
		f_dat_o <= 32'hFFFFFFFF;
		w_dat1_o <= 64'h0011223344556677;
		tick(16'hFFFF);

		// During reset, the result of the instruction decoder must be a bubble.
		reset_o <= 1;
		tick(16'h0000);
		assert_bubble();

		// When not in reset, any unacknowledged value on the F-bus must be treated as a bubble.
		reset_o <= 0;
		f_ack_o <= 0;
		tick(16'h0100);
		assert_bubble();

		// When executing ADDI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_000_00010_0010011;
		tick(16'h0200);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);

		// When executing SLLI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_001_00010_0010011;
		tick(16'h0210);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLL);
		assert_mem(0);

		// When executing SLTI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_010_00010_0010011;
		tick(16'h0220);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLT);
		assert_mem(0);

		// When executing SLTIU X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_011_00010_0010011;
		tick(16'h0230);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLTU);
		assert_mem(0);

		// When executing XORI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_100_00010_0010011;
		tick(16'h0240);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_XOR);
		assert_mem(0);

		// When executing SRLI/SRAI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_101_00010_0010011;
		tick(16'h0250);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SRL);
		assert_mem(0);

		// When executing SRLI/SRAI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b010000000100_00011_101_00010_0010011;
		tick(16'h0258);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SRA);
		assert_mem(0);

		// When executing ORI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_110_00010_0010011;
		tick(16'h0260);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_OR);
		assert_mem(0);

		// When executing ANDI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_ack_o <= 1;
		f_dat_o <= 32'b000000000100_00011_111_00010_0010011;
		tick(16'h0270);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_AND);
		assert_mem(0);

		// When executing ADDI X2, X3, -4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be -4.
		f_ack_o <= 1;
		f_dat_o <= 32'b111111111100_00011_000_00010_0010011;
		tick(16'h0280);
		assert_vs2(-4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);

		$display("@I Done.");
		$stop;
	end
endmodule
