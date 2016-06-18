`timescale 1ns / 1ps

// Exercise the Polaris integer register set, a 2-read-1-write bank of
// registers.

module test_xprs();
	reg [15:0] story_o;

	reg clk_o;

	reg [4:0] rd_o;		// Destination register address (0..31)
	reg we_o;		// 1 to enable destination register write
	reg [63:0] d_o;		// destination data value
	reg [4:0] rs1_o;	// First source register address (0..31)
	reg [4:0] rs2_o;	// Second source register address (0..31)
	wire [63:0] q_i;	// First source register value
	wire [63:0] q2_i;	// Second source register value

	// Pretend we have a 100MHz clock.
	always begin
		#10 clk_o <= ~clk_o;
	end

	// Core Under Test
	xprs xs(
		.clk_i(clk_o),
		.we_i(we_o),
		.rd_i(rd_o),
		.rs1_i(rs1_o),
		.rs2_i(rs2_o),
		.d_i(d_o),
		.q1_o(q_i),
		.q2_o(q2_i)
	);

	// Load register with data.  The task is based on the test code
	// developed for story 16'h0000.

	task ldreg;
	input [15:0] story;
	input [4:0] regAddr;
	input [63:0] regData;
	begin
		if(regAddr === 0) begin
			$display("@E %04X Destination register should fall between 1..31; got %d", story, regAddr);
			$stop;
		end
		rd_o <= regAddr;
		we_o <= 1;
		d_o <= regData;
		wait(clk_o); wait(~clk_o);
		we_o <= 0;
	end
	endtask

	// Check register contents through port 1.

	task chkreg;
	input [15:0] story;
	input [4:0] regAddr;
	input [63:0] expData;
	begin
		we_o <= 0;
		rs1_o <= regAddr;
		wait(clk_o); wait(~clk_o);
		if(q_i !== expData) begin
			$display("@E %04X Register %d expected $%016X; got $%016X", story, regAddr, expData, q_i);
			$stop;
		end
	end
	endtask

	// Check register contents through port 2.

	task chkreg2;
	input [15:0] story;
	input [4:0] regAddr;
	input [63:0] expData;
	begin
		we_o <= 0;
		rs2_o <= regAddr;
		wait(clk_o); wait(~clk_o);
		if(q2_i !== expData) begin
			$display("@E %04X Register %d expected $%016X; got $%016X", story, regAddr, expData, q2_i);
			$stop;
		end
	end
	endtask

	// Attempt to read and write the same register at the same time.

	task ldchk;
	input [15:0] story;
	input [4:0] regAddr;
	input [63:0] expData;
	input [63:0] newData;
	begin
		rd_o <= regAddr;
		rs1_o <= regAddr;
		rs2_o <= regAddr;
		we_o <= 1;
		d_o <= newData;
		#5 if(q_i !== expData) begin
			$display("@E %04X RS1 reports unexpected value $%016X; expected $%016X", story, q_i, expData);
			$stop;
		end
		if(q2_i !== expData) begin
			$display("@E %04X RS2 reports unexpected value $%016X; expected $%016X", story, q2_i, expData);
			$stop;
		end
		wait(clk_o); wait(~clk_o);
		we_o <= 0;
		if(|regAddr) begin
			if(q_i !== newData) begin
				$display("@E %04X RS1 reports unexpected value $%016X; expected $%016X", story, q_i, newData);
				$stop;
			end
			if(q2_i !== newData) begin
				$display("@E %04X RS2 reports unexpected value $%016X; expected $%016X", story, q2_i, newData);
				$stop;
			end
		end else begin
			if(q_i !== 0) begin
				$display("@E %04X RS1 reports unexpected value $%016X; expected $%016X", story, q_i, 0);
				$stop;
			end
			if(q2_i !== 0) begin
				$display("@E %04X RS2 reports unexpected value $%016X; expected $%016X", story, q2_i, 0);
				$stop;
			end
		end
	end
	endtask

	initial begin
		clk_o <= 0;
		wait(clk_o); wait(~clk_o);

		// Writes to the register file should occur on the rising edge
		// of the clock, but only when enabled.
		story_o <= 16'h0000;
		rd_o <= 1;
		we_o <= 0;
		d_o <= 64'hDEADBEEFFEEDFACE;
		wait(clk_o); wait(~clk_o);
		rs1_o <= 1;
		wait(clk_o); wait(~clk_o);
		if(q_i === 64'hDEADBEEFFEEDFACE) begin
			$display("@E %04X Did not assert write enable yet.", story_o);
			$stop;
		end

		rd_o <= 1;
		we_o <= 1;
		d_o <= 64'hDEADBEEFFEEDFACE;
		wait(clk_o); wait(~clk_o);
		rs1_o <= 1;
		we_o <= 0;
		wait(clk_o); wait(~clk_o);
		if(q_i !== 64'hDEADBEEFFEEDFACE) begin
			$display("@E %04X Expected R1 to be $DEADBEEFFEEDFACE; got $%016X.", story_o, q_i);
			$stop;
		end

		// Fill all 31 registers with data.  Then, check to make sure
		// the data is actually written.
		story_o <= 16'h0100;
		ldreg(story_o, 1, 64'h1111111111111111);
		ldreg(story_o, 2, 64'h2222222222222222);
		ldreg(story_o, 3, 64'h3333333333333333);
		ldreg(story_o, 4, 64'h4444444444444444);
		ldreg(story_o, 5, 64'h5555555555555555);
		ldreg(story_o, 6, 64'h6666666666666666);
		ldreg(story_o, 7, 64'h7777777777777777);
		ldreg(story_o, 8, 64'h8888888888888888);
		ldreg(story_o, 9, 64'h9999999999999999);
		ldreg(story_o, 10, 64'hAAAAAAAAAAAAAAAA);
		ldreg(story_o, 11, 64'hBBBBBBBBBBBBBBBB);
		ldreg(story_o, 12, 64'hCCCCCCCCCCCCCCCC);
		ldreg(story_o, 13, 64'hDDDDDDDDDDDDDDDD);
		ldreg(story_o, 14, 64'hEEEEEEEEEEEEEEEE);
		ldreg(story_o, 15, 64'hFFFFFFFFFFFFFFFF);
		ldreg(story_o, 16, 64'hFFFFFFFFFFFFFFFF);
		ldreg(story_o, 17, 64'hEEEEEEEEEEEEEEEE);
		ldreg(story_o, 18, 64'hDDDDDDDDDDDDDDDD);
		ldreg(story_o, 19, 64'hCCCCCCCCCCCCCCCC);
		ldreg(story_o, 20, 64'hBBBBBBBBBBBBBBBB);
		ldreg(story_o, 21, 64'hAAAAAAAAAAAAAAAA);
		ldreg(story_o, 22, 64'h9999999999999999);
		ldreg(story_o, 23, 64'h8888888888888888);
		ldreg(story_o, 24, 64'h7777777777777777);
		ldreg(story_o, 25, 64'h6666666666666666);
		ldreg(story_o, 26, 64'h5555555555555555);
		ldreg(story_o, 27, 64'h4444444444444444);
		ldreg(story_o, 28, 64'h3333333333333333);
		ldreg(story_o, 29, 64'h2222222222222222);
		ldreg(story_o, 30, 64'h1111111111111111);
		ldreg(story_o, 31, 64'h0000000000000000);

		chkreg(story_o, 0, 64'h0000000000000000);
		chkreg(story_o, 1, 64'h1111111111111111);
		chkreg(story_o, 2, 64'h2222222222222222);
		chkreg(story_o, 3, 64'h3333333333333333);
		chkreg(story_o, 4, 64'h4444444444444444);
		chkreg(story_o, 5, 64'h5555555555555555);
		chkreg(story_o, 6, 64'h6666666666666666);
		chkreg(story_o, 7, 64'h7777777777777777);
		chkreg(story_o, 8, 64'h8888888888888888);
		chkreg(story_o, 9, 64'h9999999999999999);
		chkreg(story_o, 10, 64'hAAAAAAAAAAAAAAAA);
		chkreg(story_o, 11, 64'hBBBBBBBBBBBBBBBB);
		chkreg(story_o, 12, 64'hCCCCCCCCCCCCCCCC);
		chkreg(story_o, 13, 64'hDDDDDDDDDDDDDDDD);
		chkreg(story_o, 14, 64'hEEEEEEEEEEEEEEEE);
		chkreg(story_o, 15, 64'hFFFFFFFFFFFFFFFF);
		chkreg(story_o, 16, 64'hFFFFFFFFFFFFFFFF);
		chkreg(story_o, 17, 64'hEEEEEEEEEEEEEEEE);
		chkreg(story_o, 18, 64'hDDDDDDDDDDDDDDDD);
		chkreg(story_o, 19, 64'hCCCCCCCCCCCCCCCC);
		chkreg(story_o, 20, 64'hBBBBBBBBBBBBBBBB);
		chkreg(story_o, 21, 64'hAAAAAAAAAAAAAAAA);
		chkreg(story_o, 22, 64'h9999999999999999);
		chkreg(story_o, 23, 64'h8888888888888888);
		chkreg(story_o, 24, 64'h7777777777777777);
		chkreg(story_o, 25, 64'h6666666666666666);
		chkreg(story_o, 26, 64'h5555555555555555);
		chkreg(story_o, 27, 64'h4444444444444444);
		chkreg(story_o, 28, 64'h3333333333333333);
		chkreg(story_o, 29, 64'h2222222222222222);
		chkreg(story_o, 30, 64'h1111111111111111);
		chkreg(story_o, 31, 64'h0000000000000000);

		// Register port 2 should yield the same results.

		story_o <= 16'h0200;
		chkreg2(story_o, 0, 64'h0000000000000000);
		chkreg2(story_o, 1, 64'h1111111111111111);
		chkreg2(story_o, 2, 64'h2222222222222222);
		chkreg2(story_o, 3, 64'h3333333333333333);
		chkreg2(story_o, 4, 64'h4444444444444444);
		chkreg2(story_o, 5, 64'h5555555555555555);
		chkreg2(story_o, 6, 64'h6666666666666666);
		chkreg2(story_o, 7, 64'h7777777777777777);
		chkreg2(story_o, 8, 64'h8888888888888888);
		chkreg2(story_o, 9, 64'h9999999999999999);
		chkreg2(story_o, 10, 64'hAAAAAAAAAAAAAAAA);
		chkreg2(story_o, 11, 64'hBBBBBBBBBBBBBBBB);
		chkreg2(story_o, 12, 64'hCCCCCCCCCCCCCCCC);
		chkreg2(story_o, 13, 64'hDDDDDDDDDDDDDDDD);
		chkreg2(story_o, 14, 64'hEEEEEEEEEEEEEEEE);
		chkreg2(story_o, 15, 64'hFFFFFFFFFFFFFFFF);
		chkreg2(story_o, 16, 64'hFFFFFFFFFFFFFFFF);
		chkreg2(story_o, 17, 64'hEEEEEEEEEEEEEEEE);
		chkreg2(story_o, 18, 64'hDDDDDDDDDDDDDDDD);
		chkreg2(story_o, 19, 64'hCCCCCCCCCCCCCCCC);
		chkreg2(story_o, 20, 64'hBBBBBBBBBBBBBBBB);
		chkreg2(story_o, 21, 64'hAAAAAAAAAAAAAAAA);
		chkreg2(story_o, 22, 64'h9999999999999999);
		chkreg2(story_o, 23, 64'h8888888888888888);
		chkreg2(story_o, 24, 64'h7777777777777777);
		chkreg2(story_o, 25, 64'h6666666666666666);
		chkreg2(story_o, 26, 64'h5555555555555555);
		chkreg2(story_o, 27, 64'h4444444444444444);
		chkreg2(story_o, 28, 64'h3333333333333333);
		chkreg2(story_o, 29, 64'h2222222222222222);
		chkreg2(story_o, 30, 64'h1111111111111111);
		chkreg2(story_o, 31, 64'h0000000000000000);

		// A register read is asynchronous, but a write is not.
		// if the processor wants to read from, say, register 5
		// and write to it at the same time, then the read will
		// yield the old value up until the next rising edge
		// of the clock.

		story_o <= 16'h0300;
		ldchk(story_o, 0, 64'h0000000000000000, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 1, 64'h1111111111111111, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 2, 64'h2222222222222222, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 3, 64'h3333333333333333, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 4, 64'h4444444444444444, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 5, 64'h5555555555555555, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 6, 64'h6666666666666666, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 7, 64'h7777777777777777, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 8, 64'h8888888888888888, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 9, 64'h9999999999999999, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 10, 64'hAAAAAAAAAAAAAAAA, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 11, 64'hBBBBBBBBBBBBBBBB, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 12, 64'hCCCCCCCCCCCCCCCC, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 13, 64'hDDDDDDDDDDDDDDDD, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 14, 64'hEEEEEEEEEEEEEEEE, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 15, 64'hFFFFFFFFFFFFFFFF, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 16, 64'hFFFFFFFFFFFFFFFF, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 17, 64'hEEEEEEEEEEEEEEEE, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 18, 64'hDDDDDDDDDDDDDDDD, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 19, 64'hCCCCCCCCCCCCCCCC, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 20, 64'hBBBBBBBBBBBBBBBB, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 21, 64'hAAAAAAAAAAAAAAAA, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 22, 64'h9999999999999999, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 23, 64'h8888888888888888, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 24, 64'h7777777777777777, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 25, 64'h6666666666666666, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 26, 64'h5555555555555555, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 27, 64'h4444444444444444, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 28, 64'h3333333333333333, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 29, 64'h2222222222222222, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 30, 64'h1111111111111111, 64'hDEADBEEFFEEDFACE);
		ldchk(story_o, 31, 64'h0000000000000000, 64'hDEADBEEFFEEDFACE);
	
		$display("@I Done.");
		$stop;
	end
endmodule

