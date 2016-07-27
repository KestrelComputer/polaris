`timescale 1ns / 1ps

// The decode module is a passive module taking a current state, instruction,
// and other parameters, and yielding one or more minterms to help control
// other functional units in the CPU.

module decode(
);

endmodule


// Exercise the instruction decode module.

module test_decode();
	reg [15:0] story_o;
	reg clk_o;
	reg reset_o;
	reg ir_o;
	reg [2:0] state_o;

	wire alu_imm12_i;
	wire defined_i;
	wire [2:0] nstate_i;
	wire ra_ir1_i;
	wire ra_ird_i;
	wire alua_rf_i;
	wire rf_alu_i;
	wire [3:0] rmask_i;
	wire cflag_1_i, sum_en_i, and_en_i, xor_en_i, invB_en_i, lsh_en_i, rsh_en_i;

	decode d(
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

	task assert_alu_imm12;
	input expected;
	begin
		if(expected !== alu_imm12_i) begin
			$display("@E %04X ALU_IMM12_O Expected %d; got %d", expected, alu_imm12_i);
			$stop;
		end
	end
	endtask

	task assert_ra_ir1;
	input expected;
	begin
		if(expected !== ra_ir1_i) begin
			$display("@E %04X RA_IR1_O Expected %d; got %d", expected, ra_ir1_i);
			$stop;
		end
	end
	endtask

	task assert_ra_ird;
	input expected;
	begin
		if(expected !== ra_ird_i) begin
			$display("@E %04X RA_IRD_O Expected %d; got %d", expected, ra_ird_i);
			$stop;
		end
	end
	endtask

	task assert_alua_rf;
	input expected;
	begin
		if(expected !== alua_rf_i) begin
			$display("@E %04X ALUA_RF_O Expected %d; got %d", expected, alua_rf_i);
			$stop;
		end
	end
	endtask

	task assert_rf_alu;
	input expected;
	begin
		if(expected !== rf_alu_i) begin
			$display("@E %04X RF_ALU_O Expected %d; got %d", expected, rf_alu_i);
			$stop;
		end
	end
	endtask

	task assert_nstate;
	input [2:0] expected;
	begin
		if(expected !== nstate_i) begin
			$display("@E %04X NSTATE_O Expected %d; got %d", expected, nstate_i);
			$stop;
		end
	end
	endtask

	task assert_rmask;
	input [3:0] expected;
	begin
		if(expected !== rmask_i) begin
			$display("@E %04X RMASK_O Expected %X; got %X", expected, rmask_i);
			$stop;
		end
	end
	endtask

	task assert_alu_op;
	input cflag_e, sum_en_e, and_en_e, xor_en_e, invB_en_e, lsh_en_e, rsh_en_e;
	begin
		if(cflag_e !== cflag_1_i) begin
			$display("@E %04X CFLAG_1_O Expected %d; got %d", cflag_e, cflag_1_i);
			$stop;
		end
		if(sum_en_e !== sum_en_i) begin
			$display("@E %04X SUM_EN_O Expected %d; got %d", sum_en_e, sum_en_i);
			$stop;
		end
		if(and_en_e !== and_en_i) begin
			$display("@E %04X AND_EN_O Expected %d; got %d", and_en_e, and_en_i);
			$stop;
		end
		if(xor_en_e !== xor_en_i) begin
			$display("@E %04X XOR_EN_O Expected %d; got %d", xor_en_e, xor_en_i);
			$stop;
		end
		if(invB_en_e !== invB_en_i) begin
			$display("@E %04X INVB_EN_O Expected %d; got %d", invB_en_e, invB_en_i);
			$stop;
		end
		if(lsh_en_e !== lsh_en_i) begin
			$display("@E %04X LSH_EN_O Expected %d; got %d", lsh_en_e, lsh_en_i);
			$stop;
		end
		if(rsh_en_e !== rsh_en_i) begin
			$display("@E %04X RSH_EN_O Expected %d; got %d", rsh_en_e, rsh_en_i);
			$stop;
		end
	end
	endtask

	initial begin
		clk_o <= 0;
		reset_o <= 0;
		tick(16'hFFFF);

		// I should be able to ADDI X1, X0, $042 and get $42 stuffed into X1.

		ir_o <= 32'b000001000010_00000_000_00001_0010011;
		state_o <= 0;
		tick(16'h0000);	// ---- CYCLE 0: Load ALU_B with immediate value.
		assert_defined(1);
		assert_alu_imm12(1);
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
		assert_alu_op(0,1,0,0,0,0,0);

		state_o <= nstate_i;
		tick(16'h0003);	// ---- CYCLE 3: Wait for next instruction fetch.
		assert_defined(1);
		assert_nstate(3);


		$display("@DONE");
		$stop;
	end
endmodule

