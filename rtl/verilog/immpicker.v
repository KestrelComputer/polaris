`timescale 1ns / 1ps

// This logic calculates the correct immediate value for the specified type
// of instruction.
//
// Note that U-type constants are proper 32-bit constants, but with bits 11-0 hard-wired to zero.
// UJ-type displacements are byte offsets (with halfword resolution).

module immpicker(
	input [31:0] instruction_i,	// Instruction word
	input typeI_i,			// What kind of instruction is it?
	input typeS_i,
	input typeSB_i,
	input typeU_i,
	input typeUJ_i,

	output [63:0] value_o		// Resulting sign-ext immediate value
);
	wire [11:0] imm12i = instruction_i[31:20];
	wire [11:0] imm12s = {instruction_i[31:25], instruction_i[11:7]};
	wire [12:0] disp13 = {instruction_i[31], instruction_i[7], instruction_i[30:25], instruction_i[11:8], 1'b0};
	wire [31:0] imm20u = {instruction_i[31:12], 12'b0};
	wire [20:0] disp21 = {instruction_i[31], instruction_i[19:12], instruction_i[20], instruction_i[30:21], 1'b0};

	wire [63:0] sx_imm12i = {{52{imm12i[11]}}, imm12i} & {64{typeI_i}};
	wire [63:0] sx_imm12s = {{52{imm12s[11]}}, imm12s} & {64{typeS_i}};
	wire [63:0] sx_disp13 = {{51{disp13[12]}}, disp13} & {64{typeSB_i}};
	wire [63:0] sx_imm20u = {{32{imm20u[31]}}, imm20u} & {64{typeU_i}};
	wire [63:0] sx_disp21 = {{43{disp21[20]}}, disp21} & {64{typeUJ_i}};

	assign value_o = sx_imm12i | sx_imm12s | sx_disp13 | sx_imm20u | sx_disp21;
endmodule

