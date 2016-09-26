`timescale 1ns / 1ps

`define PHASE 20	// 20ns per phase, 40ns per cycle, 25MHz

module PolarisCPU(
	// MISC DIAGNOSTICS

	output			jammed_o,

	// I MASTER

	input			iack_i,
	input	[31:0]		idat_i,
	output	[63:0]		iadr_o,
	output	[1:0]		isiz_o,

	// SYSCON

	input			clk_i,
	input			reset_i
);
	// Sequencer outputs
	wire		pc_mbvec, pc_pcPlus4;
	wire		ft0_o;
	wire		iadr_pc;
	wire		isiz_2;
	wire		ir_idat;

	// Sequencer inputs
	reg		ft0;

	// Internal working wires and registers
	reg		rst;
	reg	[63:0]	pc;
	wire	[63:0]	pc_mux;
	reg	[31:0]	ir;
	wire	[31:0]	ir_mux;
	reg		xt0, xt1, xt2, xt3;
	wire		xt0_o, xt1_o, xt2_o, xt3_o;
	wire	[4:0]	ra_mux;
	wire		ra_ir1, ra_ird;
	wire		rdat_alu, rdat_pc;
	wire	[63:0]	rdat_i, rdat_o;
	wire		rwe_o;
	reg	[63:0]	alua, alub;
	wire	[63:0]	alua_mux, alub_mux;
	wire		alua_rdat, alub_imm12i;
	wire	[63:0]	imm12i;
	wire		pc_alu;
	wire		cflag_i;
	wire		sum_en;
	wire		and_en;
	wire		xor_en;
	wire		invB_en;
	wire		lsh_en;
	wire		rsh_en;
	wire	[63:0]	aluResult, aluXResult;
	wire		cflag_o;
	wire		vflag_o;
	wire		zflag_o;
	wire	[3:0]	rmask_i;
	wire		sx32_en;

	assign aluXResult = (sx32_en ? {{32{aluResult[31]}}, aluResult[31:0]} : aluResult);
	assign imm12i = {{52{ir[31]}}, ir[31:20]};
	assign alua_mux =
			(alua_rdat ? rdat_o : 0);
	assign alub_mux =
			(alub_imm12i ? imm12i : 0);
	assign rdat_i = (rdat_alu ? aluXResult : 0) |
			(rdat_pc ? pc : 0);
	assign ra_mux = (ra_ir1 ? ir[19:15] : 0) |
			(ra_ird ? ir[11:7] : 0);	// Defaults to 0
	assign isiz_o = isiz_2 ? 2'b10 : 2'b00;
	wire pc_pc    = ~|{pc_mbvec,pc_pcPlus4,pc_alu};
	assign pc_mux = (pc_mbvec ? 64'hFFFF_FFFF_FFFF_FF00 : 64'h0) |
			(pc_pcPlus4 ? pc + 4 : 64'h0) |
			(pc_alu ? aluXResult : 64'h0) |
			(pc_pc ? pc : 64'h0);	// base case
	assign iadr_o = iadr_pc ? pc : 0;
	wire ir_ir    = ~ir_idat;
	assign ir_mux = (ir_idat ? idat_i : 0) |
			(ir_ir ? ir : 0);	// base case

	always @(posedge clk_i) begin
		rst <= reset_i;
		pc <= pc_mux;
		ft0 <= ft0_o;
		xt0 <= xt0_o;
		xt1 <= xt1_o;
		xt2 <= xt2_o;
		xt3 <= xt3_o;
		ir <= ir_mux;
		alua <= alua_mux;
		alub <= alub_mux;
	end

	Sequencer s(
		.xt0_o(xt0_o),
		.xt1_o(xt1_o),
		.xt2_o(xt2_o),
		.xt3_o(xt3_o),
		.xt0(xt0),
		.xt1(xt1),
		.xt2(xt2),
		.xt3(xt3),
		.jammed_o(jammed_o),
		.ft0(ft0),
		.isiz_2(isiz_2),
		.iadr_pc(iadr_pc),
		.iack_i(iack_i),
		.pc_mbvec(pc_mbvec),
		.pc_pcPlus4(pc_pcPlus4),
		.ir_idat(ir_idat),
		.ir(ir),
		.ft0_o(ft0_o),
		.rdat_pc(rdat_pc),
		.sum_en(sum_en),
		.pc_alu(pc_alu),
		.ra_ir1(ra_ir1),
		.ra_ird(ra_ird),
		.alua_rdat(alua_rdat),
		.alub_imm12i(alub_imm12i),
		.rwe_o(rwe_o),
		.rdat_alu(rdat_alu),
		.and_en(and_en),
		.xor_en(xor_en),
		.invB_en(invB_en),
		.lsh_en(lsh_en),
		.rsh_en(rsh_en),
		.cflag_i(cflag_i),
		.sx32_en(sx32_en),
		.rst(rst)
	);

	xrs xrs(
		.clk_i(clk_i),
		.ra_i(ra_mux),
		.rdat_i(rdat_i),
		.rdat_o(rdat_o),
		.rmask_i({4{rwe_o}})
	);

	alu alu(
		.inA_i(alua),
		.inB_i(alub),
		.cflag_i(cflag_i),
		.sum_en_i(sum_en),
		.and_en_i(and_en),
		.xor_en_i(xor_en),
		.invB_en_i(invB_en),
		.lsh_en_i(lsh_en),
		.rsh_en_i(rsh_en),
		.out_o(aluResult),
		.cflag_o(cflag_o),
		.vflag_o(vflag_o),
		.zflag_o(zflag_o)
	);

endmodule

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
		tick(55);			// SLLIW X3, X3, 32
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

	initial begin
		test_bootstrap();
		test_op_i();
		$display("@I Done."); $stop;
	end
endmodule

