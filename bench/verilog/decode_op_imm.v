`timescale 1ns / 1ps

// Exercise the instruction decode module.

module test_decode_op_imm();
	reg [15:0] story_o;
	reg clk_o;
	reg reset_o;
	reg [31:0] ir_o;
	reg [2:0] state_o;

	wire alub_imm6i_i;
	wire alub_imm12_i;		// Transfer IR[31:20] (sign-extended) to alub register.
	wire defined_i;			// Instruction is defined.
	wire [2:0] nstate_i;
	wire ra_ir1_i;
	wire ra_ird_i;
	wire alua_rf_i;
	wire rf_alu_i;
	wire [3:0] rmask_i;
	wire cflag_1_i, sum_en_i, and_en_i, xor_en_i, invB_en_i, lsh_en_i, rsh_en_i, ltu_en_i, lts_en_i, sx32_en_i;

	decode_op_imm d(
		.defined_o(defined_i),
		.alua_rf_o(alua_rf_i),
		.alub_imm6i_o(alub_imm6i_i),
		.alub_imm12_o(alub_imm12_i),
		.ra_ir1_o(ra_ir1_i),
		.ra_ird_o(ra_ird_i),
		.rf_alu_o(rf_alu_i),
		.nstate_o(nstate_i),
		.rmask_o(rmask_i),
		.cflag_1_o(cflag_1_i),
		.sum_en_o(sum_en_i),
		.and_en_o(and_en_i),
		.xor_en_o(xor_en_i),
		.invB_en_o(invB_en_i),
		.lsh_en_o(lsh_en_i),
		.rsh_en_o(rsh_en_i),
		.ltu_en_o(ltu_en_i),
		.lts_en_o(lts_en_i),
		.sx32_en_o(sx32_en_i),

		.cstate_i(state_o),
		.ir_i(ir_o)
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		@(posedge clk_o); @(negedge clk_o);
	end
	endtask

	task assert_defined;
	input expected;
	begin
		if(expected !== defined_i) begin
			$display("@E %04X DEFINED_O Expected %d; got %d", story_o, expected, defined_i);
			$stop;
		end
	end
	endtask

	task assert_alub_imm12;
	input expected;
	begin
		if(expected !== alub_imm12_i) begin
			$display("@E %04X ALUB_IMM12_O Expected %d; got %d", story_o, expected, alub_imm12_i);
			$stop;
		end
	end
	endtask

	task assert_alub_imm6i;
	input expected;
	begin
		if(expected !== alub_imm6i_i) begin
			$display("@E %04X ALUB_IMM6i_O Expected %d; got %d", story_o, expected, alub_imm6i_i);
			$stop;
		end
	end
	endtask

	task assert_ra_ir1;
	input expected;
	begin
		if(expected !== ra_ir1_i) begin
			$display("@E %04X RA_IR1_O Expected %d; got %d", story_o, expected, ra_ir1_i);
			$stop;
		end
	end
	endtask

	task assert_ra_ird;
	input expected;
	begin
		if(expected !== ra_ird_i) begin
			$display("@E %04X RA_IRD_O Expected %d; got %d", story_o, expected, ra_ird_i);
			$stop;
		end
	end
	endtask

	task assert_alua_rf;
	input expected;
	begin
		if(expected !== alua_rf_i) begin
			$display("@E %04X ALUA_RF_O Expected %d; got %d", story_o, expected, alua_rf_i);
			$stop;
		end
	end
	endtask

	task assert_rf_alu;
	input expected;
	begin
		if(expected !== rf_alu_i) begin
			$display("@E %04X RF_ALU_O Expected %d; got %d", story_o, expected, rf_alu_i);
			$stop;
		end
	end
	endtask

	task assert_nstate;
	input [2:0] expected;
	begin
		if(expected !== nstate_i) begin
			$display("@E %04X NSTATE_O Expected %d; got %d", story_o, expected, nstate_i);
			$stop;
		end
	end
	endtask

	task assert_rmask;
	input [3:0] expected;
	begin
		if(expected !== rmask_i) begin
			$display("@E %04X RMASK_O Expected %X; got %X", story_o, expected, rmask_i);
			$stop;
		end
	end
	endtask

	task assert_alu_op;
	input cflag_e, sum_en_e, and_en_e, xor_en_e, invB_en_e, lsh_en_e, rsh_en_e, ltu_en_e, lts_en_e, sx32_en_e;
	begin
		if(cflag_e !== cflag_1_i) begin
			$display("@E %04X CFLAG_1_O Expected %d; got %d", story_o, cflag_e, cflag_1_i);
			$stop;
		end
		if(sum_en_e !== sum_en_i) begin
			$display("@E %04X SUM_EN_O Expected %d; got %d", story_o, sum_en_e, sum_en_i);
			$stop;
		end
		if(and_en_e !== and_en_i) begin
			$display("@E %04X AND_EN_O Expected %d; got %d", story_o, and_en_e, and_en_i);
			$stop;
		end
		if(xor_en_e !== xor_en_i) begin
			$display("@E %04X XOR_EN_O Expected %d; got %d", story_o, xor_en_e, xor_en_i);
			$stop;
		end
		if(invB_en_e !== invB_en_i) begin
			$display("@E %04X INVB_EN_O Expected %d; got %d", story_o, invB_en_e, invB_en_i);
			$stop;
		end
		if(lsh_en_e !== lsh_en_i) begin
			$display("@E %04X LSH_EN_O Expected %d; got %d", story_o, lsh_en_e, lsh_en_i);
			$stop;
		end
		if(rsh_en_e !== rsh_en_i) begin
			$display("@E %04X RSH_EN_O Expected %d; got %d", story_o, rsh_en_e, rsh_en_i);
			$stop;
		end
		if(ltu_en_e !== ltu_en_i) begin
			$display("@E %04X LTU_EN_O Expected %d; got %d", story_o, ltu_en_e, ltu_en_i);
			$stop;
		end
		if(lts_en_e !== lts_en_i) begin
			$display("@E %04X LTS_EN_O Expected %d; got %d", story_o, lts_en_e, lts_en_i);
			$stop;
		end
		if(sx32_en_e !== sx32_en_i) begin
			$display("@E %04X SX32_EN_O Expected %d; got %d", story_o, sx32_en_e, sx32_en_i);
			$stop;
		end
	end
	endtask

	initial begin
		clk_o <= 0;
		reset_o <= 0;
		tick(16'hFFFF);

		// I should be able to ADDI X1, X0, $042 and get $42 stuffed into X1.

		ir_o <= 32'b000000000010_00000_001_00001_0010011;
		state_o <= 0;
		tick(16'h0000);	// ---- CYCLE 0: Load ALU_B with immediate value.
		assert_defined(1);
		assert_alub_imm6i(1);
		assert_alub_imm12(0);
		assert_nstate(1);

		ir_o <= 32'b000001000010_00000_000_00001_0010011;
		state_o <= 0;
		tick(16'h8000);
		assert_defined(1);
		assert_alub_imm6i(0);
		assert_alub_imm12(1);
		assert_nstate(1);

		state_o <= nstate_i;
		tick(16'h0001); // ---- CYCLE 1: Fetch Rs1
		assert_defined(1);
		assert_nstate(2);
		assert_ra_ir1(1);

		state_o <= nstate_i;
		tick(16'h0002);	// ---- CYCLE 2: Add, and store result.
		assert_defined(1);
		assert_nstate(3);
		assert_alua_rf(1);  // read from register file
		assert_ra_ird(1);
		assert_rf_alu(1);
		assert_rmask(4'b1111);
		assert_alu_op(0,1,0,0,0,0,0,0,0,0);

		// While we're here, might as well cycle through our 8 other functions.

		ir_o <= 32'b000000000010_00000_001_00001_0010011;
		tick(16'h1002);
		assert_defined(1);
		assert_alu_op(0,0,0,0,0,1,0,0,0,0);

		ir_o <= 32'b000001000010_00000_001_00001_0010011;
		tick(16'h1102);
		assert_defined(0);

		ir_o <= 32'b000010000010_00000_001_00001_0010011;
		tick(16'h1202);
		assert_defined(0);

		ir_o <= 32'b000100000010_00000_001_00001_0010011;
		tick(16'h1302);
		assert_defined(0);

		ir_o <= 32'b001000000010_00000_001_00001_0010011;
		tick(16'h1402);
		assert_defined(0);

		ir_o <= 32'b010000000010_00000_001_00001_0010011;
		tick(16'h1502);
		assert_defined(0);

		ir_o <= 32'b100000000010_00000_001_00001_0010011;
		tick(16'h1602);
		assert_defined(0);

		ir_o <= 32'b000001000010_00000_010_00001_0010011;
		tick(16'h2002);
		assert_defined(1);
		assert_alu_op(1,0,0,0,1,0,0,0,1,0);

		ir_o <= 32'b000001000010_00000_011_00001_0010011;
		tick(16'h3002);
		assert_defined(1);
		assert_alu_op(1,0,0,0,1,0,0,1,0,0);

		ir_o <= 32'b000001000010_00000_100_00001_0010011;
		tick(16'h4002);
		assert_defined(1);
		assert_alu_op(0,0,0,1,0,0,0,0,0,0);

		ir_o <= 32'b000000000010_00000_101_00001_0010011;
		tick(16'h5002);
		assert_defined(1);
		assert_alu_op(0,0,0,0,0,0,1,0,0,0);

		ir_o <= 32'b010000000010_00000_101_00001_0010011;
		tick(16'h5102);
		assert_defined(1);
		assert_alu_op(1,0,0,0,0,0,1,0,0,0);

		ir_o <= 32'b010001000010_00000_101_00001_0010011;
		tick(16'h5202);
		assert_defined(0);

		ir_o <= 32'b010010000010_00000_101_00001_0010011;
		tick(16'h5302);
		assert_defined(0);

		ir_o <= 32'b010100000010_00000_101_00001_0010011;
		tick(16'h5402);
		assert_defined(0);

		ir_o <= 32'b011000000010_00000_101_00001_0010011;
		tick(16'h5502);
		assert_defined(0);

		ir_o <= 32'b110000000010_00000_101_00001_0010011;
		tick(16'h5602);
		assert_defined(0);

		ir_o <= 32'b000001000010_00000_110_00001_0010011;
		tick(16'h6002);
		assert_defined(1);
		assert_alu_op(0,0,1,1,0,0,0,0,0,0);

		ir_o <= 32'b000001000010_00000_111_00001_0010011;
		tick(16'h7002);
		assert_defined(1);
		assert_alu_op(0,0,1,0,0,0,0,0,0,0);

		// Try OP-IMM-32 instructions.  Some combinations are
		// "undocumented opcodes", in the NMOS 6502 sense, because it
		// saves on logic.  That technically makes these instructions
		// bugs; don't use them for anything official.  That said,
		// they're obvious and logical extensions of their OP-IMM
		// forms.
		//
		// In case you're wondering, the only difference between OP-IMM
		// and OP-IMM-32 forms is the latter sign-extends from a 32-bit
		// result.  I've never had a need to use one of these
		// instructions, but RISC-V defines the following:
		//
		// ADDIW, SLLIW, SRLIW, SRAIW, ADDW, SUBW, SLLW, SRLW, SRAW
		//
		// The following forms are "undocumented", and should be
		// avoided:
		//
		// SLTIW, SLTIUW, XORIW, ORIW, ANDIW, SLTW, SLTUW, XORW, ORW,
		// ANDW

		ir_o <= 32'b000000000010_00000_001_00001_0011011;
		tick(16'h1802);
		assert_defined(1);
		assert_alu_op(0,0,0,0,0,1,0,0,0,1);

		ir_o <= 32'b000000100010_00000_001_00001_0011011;	// Note: shamt is 5-bit field for this instruction.
		tick(16'h1902);
		assert_defined(0);

		ir_o <= 32'b000001000010_00000_001_00001_0011011;
		tick(16'h1982);
		assert_defined(0);

		ir_o <= 32'b000010000010_00000_001_00001_0011011;
		tick(16'h1A02);
		assert_defined(0);

		ir_o <= 32'b000100000010_00000_001_00001_0011011;
		tick(16'h1B02);
		assert_defined(0);

		ir_o <= 32'b001000000010_00000_001_00001_0011011;
		tick(16'h1C02);
		assert_defined(0);

		ir_o <= 32'b010000000010_00000_001_00001_0011011;
		tick(16'h1D02);
		assert_defined(0);

		ir_o <= 32'b100000000010_00000_001_00001_0011011;
		tick(16'h1E02);
		assert_defined(0);

		ir_o <= 32'b000001000010_00000_010_00001_0011011;
		tick(16'h2802);
		assert_defined(1);
		assert_alu_op(1,0,0,0,1,0,0,0,1,1);

		ir_o <= 32'b000001000010_00000_011_00001_0011011;
		tick(16'h3802);
		assert_defined(1);
		assert_alu_op(1,0,0,0,1,0,0,1,0,1);

		ir_o <= 32'b000001000010_00000_100_00001_0011011;
		tick(16'h4802);
		assert_defined(1);
		assert_alu_op(0,0,0,1,0,0,0,0,0,1);

		ir_o <= 32'b000000000010_00000_101_00001_0011011;
		tick(16'h5802);
		assert_defined(1);
		assert_alu_op(0,0,0,0,0,0,1,0,0,1);

		ir_o <= 32'b010000000010_00000_101_00001_0011011;
		tick(16'h5902);
		assert_defined(1);
		assert_alu_op(1,0,0,0,0,0,1,0,0,1);

		ir_o <= 32'b010001000010_00000_101_00001_0011011;
		tick(16'h5A02);
		assert_defined(0);

		ir_o <= 32'b010010000010_00000_101_00001_0011011;
		tick(16'h5B02);
		assert_defined(0);

		ir_o <= 32'b010100000010_00000_101_00001_0011011;
		tick(16'h5C02);
		assert_defined(0);

		ir_o <= 32'b011000000010_00000_101_00001_0011011;
		tick(16'h5D02);
		assert_defined(0);

		ir_o <= 32'b110000000010_00000_101_00001_0011011;
		tick(16'h5E02);
		assert_defined(0);

		ir_o <= 32'b000001000010_00000_110_00001_0011011;
		tick(16'h6802);
		assert_defined(1);
		assert_alu_op(0,0,1,1,0,0,0,0,0,1);

		ir_o <= 32'b000001000010_00000_111_00001_0011011;
		tick(16'h7802);
		assert_defined(1);
		assert_alu_op(0,0,1,0,0,0,0,0,0,1);


		state_o <= nstate_i;
		tick(16'h0003);	// ---- CYCLE 3: Wait for next instruction fetch.
		assert_defined(1);
		assert_nstate(3);


		$display("@DONE");
		$stop;
	end
endmodule

