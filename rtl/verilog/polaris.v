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

	// D MASTER

	input			dack_i,
	input	[63:0]		ddat_i,
	output	[63:0]		ddat_o,
	output	[63:0]		dadr_o,
	output			dwe_o,
	output			dcyc_o,
	output			dstb_o,
	output	[1:0]		dsiz_o,
	output			dsigned_o,

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
	reg	[63:0]	pc, ia;
	wire	[63:0]	pc_mux, ia_mux;
	reg	[31:0]	ir;
	wire	[31:0]	ir_mux;
	reg		xt0, xt1, xt2, xt3;
	wire		xt0_o, xt1_o, xt2_o, xt3_o;
	wire	[4:0]	ra_mux;
	wire		ra_ir1, ra_ir2, ra_ird;
	wire		rdat_alu, rdat_pc;
	wire	[63:0]	rdat_i, rdat_o;
	wire		rwe_o;
	reg	[63:0]	alua, alub;
	wire	[63:0]	alua_mux, alub_mux;
	wire		alua_rdat, alua_0, alua_ia;
	wire		alub_rdat, alub_imm12i, alub_imm20u;
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
	wire		alua_alua;
	wire		alub_alub;
	wire	[63:0]	imm20u;
	wire		ia_pc;
	wire		dadr_alu;
	wire		dcyc_1;
	wire		dstb_1;
	wire		dsiz_fn3;
	wire		rdat_ddat;

	assign dsigned_o = dsiz_fn3 & ~ir[14];
	assign dsiz_o = dsiz_fn3 ? ir[13:12] : 2'b00;
	assign dwe_o = 0;
	assign dcyc_o = dcyc_1;
	assign dstb_o = dstb_1;
	assign dadr_o = (dadr_alu ? aluXResult : 64'd0);

	assign aluXResult = (sx32_en ? {{32{aluResult[31]}}, aluResult[31:0]} : aluResult);
	assign imm12i = {{52{ir[31]}}, ir[31:20]};
	assign imm20u = {{32{ir[31]}}, ir[31:12], 12'd0};
	assign alua_alua = ~|{alua_rdat, alua_0, alua_ia};
	assign alub_alub = ~|{alub_rdat, alub_imm12i, alub_imm20u};
	assign alua_mux =	// ignore alua_0 since that will force alua=0.
			(alua_ia ? ia : 0) |
			(alua_rdat ? rdat_o : 0) |
			(alua_alua ? alua : 0);
	assign alub_mux =
			(alub_rdat ? rdat_o : 0) |
			(alub_imm12i ? imm12i : 0) |
			(alub_imm20u ? imm20u : 0) |
			(alub_alub ? alub : 0);
	assign rdat_i = (rdat_alu ? aluXResult : 0) |
			(rdat_ddat ? ddat_i : 0) |
			(rdat_pc ? pc : 0);
	assign ra_mux = (ra_ir1 ? ir[19:15] : 0) |
			(ra_ir2 ? ir[24:20] : 0) |
			(ra_ird ? ir[11:7] : 0);	// Defaults to 0
	assign isiz_o = isiz_2 ? 2'b10 : 2'b00;
	wire pc_pc    = ~|{pc_mbvec,pc_pcPlus4,pc_alu};
	assign pc_mux = (pc_mbvec ? 64'hFFFF_FFFF_FFFF_FF00 : 64'h0) |
			(pc_pcPlus4 ? pc + 4 : 64'h0) |
			(pc_alu ? aluXResult : 64'h0) |
			(pc_pc ? pc : 64'h0);	// base case
	wire ia_ia    = ~ia_pc;
        assign ia_mux = (ia_pc ? pc : 0) |
			(ia_ia ? ia : 0);
	assign iadr_o = iadr_pc ? pc : 0;
	wire ir_ir    = ~ir_idat;
	assign ir_mux = (ir_idat ? idat_i : 0) |
			(ir_ir ? ir : 0);	// base case

	always @(posedge clk_i) begin
		rst <= reset_i;
		pc <= pc_mux;
		ia <= ia_mux;
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
		.ra_ir2(ra_ir2),
		.ra_ird(ra_ird),
		.alua_rdat(alua_rdat),
		.alub_rdat(alub_rdat),
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
		.alua_0(alua_0),
		.alub_imm20u(alub_imm20u),
		.ia_pc(ia_pc),
		.alua_ia(alua_ia),
		.dadr_alu(dadr_alu),
		.dcyc_1(dcyc_1),
		.dstb_1(dstb_1),
		.dsiz_fn3(dsiz_fn3),
		.rdat_ddat(rdat_ddat),
		.dack_i(dack_i),
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

