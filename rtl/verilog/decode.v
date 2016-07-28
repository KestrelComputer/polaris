`timescale 1ns / 1ps

// The decode module is a passive module taking a current state, instruction,
// and other parameters, and yielding one or more minterms to help control
// other functional units in the CPU.

module decode(
	output		defined_o,
	output		alua_rf_o,
	output		alub_imm6i_o,
	output		alub_imm12_o,
	output		ra_ir1_o,
	output		ra_ird_o,
	output		rf_alu_o,
	output	[2:0]	nstate_o,
	output	[3:0]	rmask_o,
	output		cflag_1_o,
	output		sum_en_o,
	output		and_en_o,
	output		xor_en_o,
	output		invB_en_o,
	output		lsh_en_o,
	output		rsh_en_o,
	output		ltu_en_o,
	output		lts_en_o,
	output		sx32_en_o,

	input	[2:0]	cstate_i,
	input	[31:0]	ir_i
);
	wire s0 = (cstate_i == 3'b000);
	wire s1 = (cstate_i == 3'b001);
	wire s2 = (cstate_i == 3'b010);

	wire fn0 = ir_i[14:12] == 3'd0;
	wire fn1 = ir_i[14:12] == 3'd1;
	wire fn2 = ir_i[14:12] == 3'd2;
	wire fn3 = ir_i[14:12] == 3'd3;
	wire fn4 = ir_i[14:12] == 3'd4;
	wire fn5 = ir_i[14:12] == 3'd5;
	wire fn6 = ir_i[14:12] == 3'd6;
	wire fn7 = ir_i[14:12] == 3'd7;

	wire row0 = ir_i[6:5] == 2'd0;
	wire row1 = ir_i[6:5] == 2'd1;
	wire row2 = ir_i[6:5] == 2'd2;
	wire row3 = ir_i[6:5] == 2'd3;

	wire col0 = ir_i[4:2] == 3'd0;
	wire col1 = ir_i[4:2] == 3'd1;
	wire col2 = ir_i[4:2] == 3'd2;
	wire col3 = ir_i[4:2] == 3'd3;
	wire col4 = ir_i[4:2] == 3'd4;
	wire col5 = ir_i[4:2] == 3'd5;
	wire col6 = ir_i[4:2] == 3'd6;
	wire col7 = ir_i[4:2] == 3'd7;

	wire inst32b = ir_i[1:0] == 2'b11;

	wire is_not_shift = ~(fn1 | fn5);
	wire is_shift_left_64 = ~ir_i[3] & fn1 & ir_i[31:26] == 6'b000000;
	wire is_shift_right_64 = ~ir_i[3] & fn5 & ir_i[31] == 0 & ir_i[29:26] == 4'b0000;
	wire is_shift_left_32 = ir_i[3] & fn1 & ir_i[31:25] == 7'b0000000;
	wire is_shift_right_32 = ir_i[3] & fn5 & ir_i[31] == 0 & ir_i[29:25] == 5'b00000;
	wire is_shift_left = is_shift_left_32 | is_shift_left_64;
	wire is_shift_right = is_shift_right_32 | is_shift_right_64;
	
	wire is_op_imm = row0 & col4 & inst32b & (is_not_shift | is_shift_left | is_shift_right);
	wire is_op_imm32 = row0 & col6 & inst32b & (is_not_shift | is_shift_left | is_shift_right);

	assign defined_o = is_op_imm | is_op_imm32;
	assign alua_rf_o = s2;
	assign alub_imm12_o = s0 & (is_op_imm | is_op_imm32) & (is_not_shift);
	assign alub_imm6i_o = s0 & (is_op_imm | is_op_imm32) & (~is_not_shift);
	assign ra_ir1_o = s1;
	assign ra_ird_o = s2;
	assign rf_alu_o = s2;
	assign rmask_o = s2 ? 4'b1111 : 4'b0000;
	assign cflag_1_o = s2 & (fn2 | fn3 | (fn5 & ir_i[30]));
	assign sum_en_o = s2 & fn0;
	assign and_en_o = s2 & (fn6 | fn7);
	assign xor_en_o = s2 & (fn4 | fn6);
	assign invB_en_o = s2 & (fn2 | fn3);
	assign lsh_en_o = s2 & fn1;
	assign rsh_en_o = s2 & fn5;
	assign ltu_en_o = s2 & fn3;
	assign lts_en_o = s2 & fn2;
	assign sx32_en_o = s2 & ir_i[3];

	assign nstate_o =
		s0 ? 1 :
		s1 ? 2 :
		s2 ? 3 : 3;
endmodule

