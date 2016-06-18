`timescale 1ns / 1ps
`include "alu.vh"

// This is just a heuristic test of the ALU module.  We rely on the correctness
// of the Verilog compiler to ensure we see correct results in hardware.

module test_alu();
	reg [15:0] story_o;
	reg clk_o;
	reg [3:0] op_o;
	reg [63:0] in1_o;
	reg [63:0] in2_o;
	wire [63:0] result_i;

	alu a(
		.operation_i(op_o),
		.in1_i(in1_o),
		.in2_i(in2_o),
		.result_o(result_i)
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	initial begin
		clk_o <= 0;
		in1_o <= 64'h1111333355557777;
		in2_o <= 64'h8888AAAACCCCEEEE;

		story_o <= 16'h0000;
		op_o <= `ALU_ADD;
		@(posedge clk_o);
		if(result_i !== 64'h9999ddde22226665) begin
			$display("@E %04X Expected sum $9999DDDE22226665; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0100;
		op_o <= `ALU_SUB;
		@(posedge clk_o);
		if(result_i !== 64'h8888888888888889) begin
			$display("@E %04X Expected difference $8888888888888889; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0200;
		op_o <= `ALU_SLT;
		@(posedge clk_o);
		if(result_i !== 64'h0000000000000000) begin
			$display("@E %04X Expected $1... > $8... (signed!)", story_o);
			$stop;
		end

		story_o <= 16'h0300;
		op_o <= `ALU_SLTU;
		@(posedge clk_o);
		if(result_i !== 64'h0000000000000001) begin
			$display("@E %04X Expected $1... < $8... (unsigned!)", story_o);
			$stop;
		end

		story_o <= 16'h0400;
		op_o <= `ALU_XOR;
		@(posedge clk_o);
		if(result_i !== 64'h9999999999999999) begin
			$display("@E %04X Expected $9999999999999999; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0500;
		op_o <= `ALU_OR;
		@(posedge clk_o);
		if(result_i !== 64'h9999BBBBDDDDFFFF) begin
			$display("@E %04X Expected $9999BBBBDDDDFFFF; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0600;
		op_o <= `ALU_AND;
		@(posedge clk_o);
		if(result_i !== 64'h0000222244446666) begin
			$display("@E %04X Expected $0000222244446666; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0700;
		op_o <= `ALU_SLL;
		in2_o <= 4;
		@(posedge clk_o);
		if(result_i !== 64'h1113333555577770) begin
			$display("@E %04X Expected $1113333555577770; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0800;
		op_o <= `ALU_SRL;
		@(posedge clk_o);
		if(result_i !== 64'h0111133335555777) begin
			$display("@E %04X Expected $0111133335555777; got $%016X", story_o, result_i);
			$stop;
		end

		story_o <= 16'h0900;
		op_o <= `ALU_SRA;
		in1_o <= 64'h8000000000000000;
		in2_o <= 60;
		@(posedge clk_o);
		if(result_i !== 64'hFFFFFFFFFFFFFFF8) begin
			$display("@E %04X Expected $FFFFFFFFFFFFFFF8; got $%016X", story_o, result_i);
			$stop;
		end

		$display("@I Done.");
		$stop;
	end
endmodule
