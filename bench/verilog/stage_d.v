`timescale 1ns / 1ps

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
	output		d_add_o,	// ALU should add if asserted.

	// W-stage I/O
	input	[63:0]	w_dat1_i,	// Contents of register 1 from register file (W for writeback stage)
	output	[4:0]	w_rs1_o
);
	reg [31:0] ir;		// Instruction register
	always @(posedge clk_i) begin
		ir <= (reset_i) ? 32'h00000013 : f_dat_i;
	end

	assign d_rd_o = ir[11:7];

	assign w_rs1_o = ir[19:15];
	assign d_vs1_o = {64'h0000000000000000};

	assign d_vs2_o = {52'h0000000000000, ir[31:20]};

	wire [6:0] opcode = ir[6:0];
	wire [2:0] fn3 = ir[14:12];

	reg d_add_o;
	case(opcode)
	7'b0010011: begin
		case(fn3)
		3'b000: d_add_o <= 1;
		3'b001: d_add_o <= 0;
		3'b010: d_add_o <= 0;
		3'b011: d_add_o <= 0;
		3'b100: d_add_o <= 0;
		3'b101: d_add_o <= 0;
		3'b110: d_add_o <= 0;
		3'b111: d_add_o <= 0;
		endcase
	end
	default: d_add_o <= 0
	endcase
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
	wire [63:0] vs1_i;		// Contents of register Rs1 or immediate, as appropriate
	wire [63:0] vs2_i;		// Contents of register Rs2 or immediate, as appropriate
	wire add_i;			// True if ALU should add; false otherwise.

	stage_d d(
		.clk_i(clk_o),
		.reset_i(reset_o),
		.f_ack_i(f_ack_o),
		.f_dat_i(f_dat_o),
		.d_rd_o(rd_i),
		.w_rs1_o(rs1_i),
		.d_vs1_o(vs1_i),
		.d_vs2_o(vs2_i),
		.d_add_o(add_i)
	);

	// 50MHz clock.
	always begin
		#20 clk_o <= ~clk_o;
	end

	task assert_bubble;
	begin
		if(rd_i !== 5'b00000) begin
			$display("@E %04X Expected Rd=0; got Rd=%d", story_o, rd_i);
			$stop;
		end
		if(rs1_i !== 5'b00000) begin
			$display("@E %04X Expected Rs1=0; got Rs1=%d", story_o, rs1_i);
			$stop;
		end
		if(vs1_i !== 0) begin
			$display("@E %04X Expected Vs1=$0000000000000000; got Vs1=%016X", story_o, vs1_i);
			$stop;
		end
		if(vs2_i !== 0) begin
			$display("@E %04X Expected Vs2=$0000000000000000; got Vs2=%016X", story_o, vs2_i);
			$stop;
		end
		if(add_i !== 0) begin
			$display("@E %04X Expected to be adding.", story_o);
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
		tick(16'hFFFF);

		// During reset, the result of the instruction decoder must be a bubble.
		reset_o <= 1;
		tick(16'h0000);
		assert_bubble();

		$display("@I Done.");
		$stop;
	end
endmodule
