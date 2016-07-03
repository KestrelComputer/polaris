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
	input	[63:2]	f_adr_i,	// Instruction address

	// D-stage I/O
	output	[63:0]	d_vs1_o,	// Contents of 1st operand (register or immediate as appropriate)
	output	[63:0]	d_vs2_o,	// Contents of 2nd operand (register or immediate as appropriate)
	output	[63:0]	d_vs3_o,	// Contents of 3rd operand (usually for branches)
	output	[4:0]	d_rd_o,		// Destination register for eventual write-back, or 0.
	output	[3:0]	d_alu_o,	// ALU operation.  If none, ADD if usually a safe default.
	output	[3:0]	d_mem_o,	// 0, 1, 2, 4, or 8.  0 for no memory access, otherwise indicates data width.
	output		d_signed_o,	// 0 if unsigned load; 1 if signed load; undefined otherwise.
	output		d_store_o,	// 0 if memory fetch, 1 if memory store, undefined otherwise.
	output		d_cbranch_o,	// 1 if conditional branch; 0 otherwise.

	// W-stage I/O
	input	[63:0]	w_dat1_i,	// Contents of register 1 from register file (W for writeback stage)
	output	[4:0]	w_rs1_o,
	input	[63:0]	w_dat2_i,	// Contents of register 2 from register file (W for writeback stage)
	output	[4:0]	w_rs2_o
);
	wire isBubble = reset_i | ~f_ack_i;

	reg [31:0] ir;		// Instruction register
	always @(posedge clk_i) begin
		ir <= (isBubble) ? 32'h00000013 : f_dat_i;
	end

	// Break out the various instruction fields.  Note that some fields may
	// overlap.

	wire [6:0] opcode = ir[6:0];
	assign d_rd_o = (is_store | is_cbranch) ? 0 : ir[11:7];
	wire [2:0] fn3 = ir[14:12];
	assign w_rs1_o = ir[19:15];
	assign w_rs2_o = ir[24:20];
	wire fn4sign = ~is_aluI ? ir[30] : isShift ? ir[30] : 0;
	wire [3:0] d_alu_o = force_add ? `ALU_ADD : {fn4sign, fn3};

	// These are all the different kinds of immediate operands RISC-V supports.
	wire [63:0] imm12i = {{52{ir[31]}}, ir[31:20]};		// 12-bit signed (non-shift I-format)
	wire [63:0] imm12s = {{52{ir[31]}}, ir[31:25], ir[11:7]};	// 12-bit signed (S-format)
	wire [63:0] imm6sh = {58'd0, ir[25:20]};		// 6-bit unsigned (shift I-format)
	wire [63:0] disp13 = {{51{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0};	// 13-bit displacement (SB-format)
	wire [63:0] imm20u = {{32{ir[31]}}, ir[31:12], 12'b0000_0000_0000};	// 20-bit U-format immediate
	
	// Steer data to the first ALU input for the execute stage.

	assign d_vs1_o = (isBubble | is_lui)? 64'h0000000000000000 : (is_auipc) ? {f_adr_i, 2'b00} : w_dat1_i;

	// Steer data to the second ALU input for the execute stage.

	wire is_load = opcode == 7'b0000011;
	wire is_store = opcode == 7'b0100011;
	wire is_aluI = opcode == 7'b0010011;
	wire is_alu = opcode == 7'b0110011;
	wire is_cbranch = opcode == 7'b1100011;
	wire is_lui = opcode == 7'b0110111;
	wire is_auipc = opcode == 7'b0010111;

	wire isShift = (fn3 == 3'b001) | (fn3 == 3'b101);

	wire is_I = is_load | (is_aluI & ~isShift);

	assign d_vs2_o = (is_aluI & isShift) ? imm6sh : (is_alu | is_cbranch) ? w_dat2_i : (is_store) ? imm12s : (is_lui | is_auipc) ? imm20u : imm12i;

	// Steer data to the third value bus, usually for conditional branches.

	assign d_vs3_o = (isBubble) ? 0 : disp13;

	wire d_cbranch_o = is_cbranch;

	// Control signal for M-stage.  1 if memory accoess; 0 otherwise.

	reg [3:0] d_mem_o;
	always @(*) begin
		case({is_load | is_store, fn3})
		4'b0000: d_mem_o <= 0;
		4'b0001: d_mem_o <= 0;
		4'b0010: d_mem_o <= 0;
		4'b0011: d_mem_o <= 0;
		4'b0100: d_mem_o <= 0;
		4'b0101: d_mem_o <= 0;
		4'b0110: d_mem_o <= 0;
		4'b0111: d_mem_o <= 0;
		4'b1000: d_mem_o <= 4'b0001;
		4'b1001: d_mem_o <= 4'b0010;
		4'b1010: d_mem_o <= 4'b0100;
		4'b1011: d_mem_o <= 4'b1000;
		4'b1100: d_mem_o <= 4'b0001;
		4'b1101: d_mem_o <= 4'b0010;
		4'b1110: d_mem_o <= 4'b0100;
		4'b1111: d_mem_o <= 4'b1000;
		endcase
	end
	wire force_add = is_load | is_store | is_lui | is_auipc;
	wire d_signed_o = ~fn3[2];
	assign d_store_o = is_store;
endmodule

// This module exercises the instruction decode functionality, as viewed by both the instruction fetch logic and the execute logic.

module test_stage_d();
	reg [15:0] story_o;
	reg clk_o;
	reg reset_o;

	reg f_ack_o;
	reg [31:0] f_dat_o;
	reg [63:2] f_adr_o;

	wire [4:0] rd_i;		// Destination register (X0..X31)
	wire [4:0] rs1_i;		// Source register 1 (normally goes to register file)
	wire [4:0] rs2_i;		// Source register 2 (normally goes to register file)
	reg [63:0] w_dat1_o;		// Register file's concept of register 1's value.
	reg [63:0] w_dat2_o;		// Register file's concept of register 2's value.
	wire [63:0] vs1_i;		// Contents of register Rs1 or immediate, as appropriate
	wire [63:0] vs2_i;		// Contents of register Rs2 or immediate, as appropriate
	wire [63:0] vs3_i;		// Third operand
	wire [3:0] d_alu_i;
	wire [3:0] d_mem_i;
	wire d_signed_i;
	wire d_cbranch_i;

	stage_d d(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.f_ack_i(f_ack_o),
		.f_dat_i(f_dat_o),
		.f_adr_i(f_adr_o),
		.d_rd_o(rd_i),
		.w_rs1_o(rs1_i),
		.w_rs2_o(rs2_i),
		.w_dat1_i(w_dat1_o),
		.w_dat2_i(w_dat2_o),
		.d_vs1_o(vs1_i),
		.d_vs2_o(vs2_i),
		.d_vs3_o(vs3_i),
		.d_alu_o(d_alu_i),
		.d_mem_o(d_mem_i),
		.d_signed_o(d_signed_i),
		.d_store_o(d_store_i),
		.d_cbranch_o(d_cbranch_i)
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
		assert_cbranch(0);
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

	task assert_rs2;
	input [4:0] expected;
	begin
		if(rs2_i !== expected) begin
			$display("@E %04X Expected Rs2=$%016X; got Rs2=%016X", story_o, expected, rs2_i);
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

	task assert_vs3;
	input [63:0] expected;
	begin
		if(vs3_i !== expected) begin
			$display("@E %04X Expected Vs3=$%016X; got Vs3=%016X", story_o, expected, vs3_i);
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
	input [3:0] expected;
	begin
		if(d_mem_i !== expected) begin
			$display("@E %04X Expected mem %d; got %d.", story_o, expected, d_mem_i);
			$stop;
		end
	end
	endtask

	task assert_signed;
	input expected;
	begin
		if(d_signed_i !== expected) begin
			$display("@E %04X Expected signed memory load flag %d; got %d.", story_o, expected, d_signed_i);
			$stop;
		end
	end
	endtask

	task assert_isStore;
	input expected;
	begin
		if(d_store_i !== expected) begin
			$display("@E %04X Expected store operation flag %d; got %d.", story_o, expected, d_store_i);
			$stop;
		end
	end
	endtask

	task assert_cbranch;
	input expected;
	begin
		if(d_cbranch_i !== expected) begin
			$display("@E %04X Expected conditional branch flag %d; got %d.", story_o, expected, d_cbranch_i);
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
		f_adr_o <= 62'b1111111111111111_1111111111111111_1111111111111111_11111111000000;
		w_dat1_o <= 64'h0011223344556677;
		w_dat2_o <= 64'h8899AABBCCDDEEFF;
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
		assert_cbranch(0);

		// When executing SLLI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_001_00010_0010011;
		tick(16'h0210);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLL);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SLTI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_010_00010_0010011;
		tick(16'h0220);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLT);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SLTIU X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_011_00010_0010011;
		tick(16'h0230);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SLTU);
		assert_mem(0);
		assert_cbranch(0);

		// When executing XORI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_100_00010_0010011;
		tick(16'h0240);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_XOR);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SRLI/SRAI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_101_00010_0010011;
		tick(16'h0250);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SRL);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SRLI/SRAI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b010000000100_00011_101_00010_0010011;
		tick(16'h0258);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_SRA);
		assert_mem(0);
		assert_cbranch(0);

		// When executing ORI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_110_00010_0010011;
		tick(16'h0260);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_OR);
		assert_mem(0);
		assert_cbranch(0);

		// When executing ANDI X2, X3, 4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be 4.
		f_dat_o <= 32'b000000000100_00011_111_00010_0010011;
		tick(16'h0270);
		assert_vs2(4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_AND);
		assert_mem(0);
		assert_cbranch(0);

		// When executing ADDI X2, X3, -4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be -4.
		f_dat_o <= 32'b111111111100_00011_000_00010_0010011;
		tick(16'h0280);
		assert_vs2(-4);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);
		assert_cbranch(0);

		// When executing ADD X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_000_00010_0110011;
		tick(16'h0300);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SUB X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0100000_00100_00011_000_00010_0110011;
		tick(16'h0300);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SUB);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SLL X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_001_00010_0110011;
		tick(16'h0310);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SLL);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SLT X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_010_00010_0110011;
		tick(16'h0320);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SLT);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SLTU X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_011_00010_0110011;
		tick(16'h0330);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SLTU);
		assert_mem(0);
		assert_cbranch(0);

		// When executing XOR X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_100_00010_0110011;
		tick(16'h0340);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_XOR);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SRL X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_101_00010_0110011;
		tick(16'h0350);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SRL);
		assert_mem(0);
		assert_cbranch(0);

		// When executing SRA X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0100000_00100_00011_101_00010_0110011;
		tick(16'h0358);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_SRA);
		assert_mem(0);
		assert_cbranch(0);

		// When executing OR X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_110_00010_0110011;
		tick(16'h0360);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_OR);
		assert_mem(0);
		assert_cbranch(0);

		// When executing AND X2, X3, X4, we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value of X4.
		f_dat_o <= 32'b0000000_00100_00011_111_00010_0110011;
		tick(16'h0370);
		assert_rs1(3);
		assert_rs2(4);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(2);
		assert_alu_fn(`ALU_AND);
		assert_mem(0);
		assert_cbranch(0);

		// When executing LB X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_000_00010_0000011;
		tick(16'h0400);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(1);
		assert_signed(1);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LH X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_001_00010_0000011;
		tick(16'h0410);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(2);
		assert_signed(1);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LW X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_010_00010_0000011;
		tick(16'h0420);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(4);
		assert_signed(1);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LD X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_011_00010_0000011;
		tick(16'h0430);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(8);
		assert_signed(1);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LBU X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_100_00010_0000011;
		tick(16'h0440);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(1);
		assert_signed(0);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LHU X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_101_00010_0000011;
		tick(16'h0450);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(2);
		assert_signed(0);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LWU X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_110_00010_0000011;
		tick(16'h0460);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(4);
		assert_signed(0);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing LDU X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b000000000100_00011_111_00010_0000011;
		tick(16'h0470);
		assert_rs1(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(8);
		assert_signed(0);
		assert_isStore(0);
		assert_cbranch(0);

		// When executing SB X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b0000000_00010_00011_000_00100_0100011;
		tick(16'h0500);
		assert_rs1(3);
		assert_rs2(2);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(0);
		assert_alu_fn(`ALU_ADD);
		assert_mem(1);
		assert_signed(1);
		assert_isStore(1);
		assert_cbranch(0);

		// When executing SH X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b0000000_00010_00011_001_00100_0100011;
		tick(16'h0510);
		assert_rs1(3);
		assert_rs2(2);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(0);
		assert_alu_fn(`ALU_ADD);
		assert_mem(2);
		assert_signed(1);
		assert_isStore(1);
		assert_cbranch(0);

		// When executing SW X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b0000000_00010_00011_010_00100_0100011;
		tick(16'h0520);
		assert_rs1(3);
		assert_rs2(2);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(0);
		assert_alu_fn(`ALU_ADD);
		assert_mem(4);
		assert_signed(1);
		assert_isStore(1);
		assert_cbranch(0);

		// When executing SD X2, 4(X3), we expect X2 to be the
		// destination, Vs1 to hold the value of X3, and Vs2 to be the
		// value 4.
		f_dat_o <= 32'b0000000_00010_00011_011_00100_0100011;
		tick(16'h0530);
		assert_rs1(3);
		assert_rs2(2);
		assert_vs1(64'h0011223344556677);
		assert_vs2(4);
		assert_rd(0);
		assert_alu_fn(`ALU_ADD);
		assert_mem(8);
		assert_signed(1);
		assert_isStore(1);
		assert_cbranch(0);

		// When executing BEQ X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_000_01000_1100011;
		tick(16'h0600);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SEQ);
		assert_mem(0);
		assert_cbranch(1);

		// When executing BNE X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_001_01000_1100011;
		tick(16'h0610);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SNE);
		assert_mem(0);
		assert_cbranch(1);

		// When executing BLT X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_100_01000_1100011;
		tick(16'h0640);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SLT);
		assert_mem(0);
		assert_cbranch(1);

		// When executing BGE X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_101_01000_1100011;
		tick(16'h0650);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SGE);
		assert_mem(0);
		assert_cbranch(1);

		// When executing BLTU X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_110_01000_1100011;
		tick(16'h0660);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SLTU);
		assert_mem(0);
		assert_cbranch(1);

		// When executing BGEU X2, X3, 8, we expect X2 to be Rs1,
		// X3 to be Rs2, and 8 to appear on the Vs3 bus.
		f_dat_o <= 32'b0000000_00011_00010_111_01000_1100011;
		tick(16'h0670);
		assert_rs1(2);
		assert_rs2(3);
		assert_vs1(64'h0011223344556677);
		assert_vs2(64'h8899AABBCCDDEEFF);
		assert_rd(0);
		assert_vs3(64'h0000000000000008);
		assert_alu_fn(`ALU_C_SGEU);
		assert_mem(0);
		assert_cbranch(1);

		// When executing LUI X2, 3, we expect X2 to be Rd,
		// Vs1 to be zero, Vs2 to be the immediate provided,
		// and the ALU forced to add.
		f_dat_o <= 32'b0111_0111_0111_0111_0111_00010_0110111;
		tick(16'h0700);
		assert_vs1(64'h0000000000000000);
		assert_vs2(64'h0000000077777000);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);
		assert_cbranch(0);

		f_dat_o <= 32'b1000_1000_1000_1000_1000_11101_0110111;
		tick(16'h0710);
		assert_vs1(64'h0000000000000000);
		assert_vs2(64'hFFFFFFFF88888000);
		assert_rd(29);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);
		assert_cbranch(0);

		// When executing AUIPC X2, 3, we expect X2 to be Rd, Vs1 to be
		// the instruction's address, Vs2 to be the immediate provided,
		// and the ALU forced to add.
		f_dat_o <= 32'b0000_0000_0000_0000_0001_00010_0010111;
		tick(16'h0800);
		assert_vs1(64'hFFFFFFFFFFFFFF00);
		assert_vs2(64'h0000000000001000);
		assert_rd(2);
		assert_alu_fn(`ALU_ADD);
		assert_mem(0);
		assert_cbranch(0);

		$display("@I Done.");
		$stop;
	end
endmodule
