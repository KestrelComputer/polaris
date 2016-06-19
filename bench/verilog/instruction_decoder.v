`timescale 1ns / 1ps

`include "opcodes.vh"

// This logic implements the Polaris instruction decoder.
//
// I'm kind of amazed that Polaris can get by with so few instructions.  The
// RISC-V User ISA Specification says that RV32I consists of something like 56
// instructions; but in reality, it's closer to just 14.  These instructions
// are:
//
// LUI			0110111		Rd := 0 + imm20
// AUIPC		0010111		Rd := IP + imm20
// JAL			1101111		Rd := IP + 4; PC := disp21 + IP
// JALR			1100111		Rd := IP + 4; PC := Rs1 + imm12
// Bcc			1100011.ccc	IF Rs1 .op. Rs2 THEN PC := IP + disp13 THEN
// Lx			0000011.xxx	Rd := MEMx(Rs1+imm12)
// Sx			0100011.xxx	MEMx(Rs1+imm12) := Rd
// aluI			0010011.fff	Rd := Rs1 .op. imm12
// alu			0110011.fff	Rd := Rs1 .op. Rs2
// FENCE(.I)		0001111		Wait for empty pipeline before proceeding.
// CSRRx		1110011.0xx	(needs more thought; xx != 0)
// CSRRxI		1110011.1xx	(reuse logic from CSRRx; xx != 0)
//
// There are only a small handful more needed to cover the RV64I extensions.
//
// Note that all writes to PC will flush the pipeline immediately.

module instruction_decoder(
	input	[31:0]	instruction_i,		// Instruction to decode
	output	[63:0]	immediate_o,		// Immediate field, if any.
	output		src2_immediate_o,	// Immediate field has valid data.
	output	[4:0]	rd_o,			// Destination register.
	output		rd_we_o			// Destination register writeback.
);
	wire [6:0] opcode = instruction_i[6:0];
	assign rd_o = instruction_i[11:7];
	assign rd_we_o = typeU_o;

	// Decode the instruction format type.
	wire typeU_o = (opcode === `OPC_LUI) | (opcode === `OPC_AUIPC);
	wire typeUJ_o = (opcode === `OPC_JAL);
	wire typeI_o = (opcode === `OPC_JALR) | (opcode === `OPC_Lx) | (opcode === `OPC_aluI) | (opcode === `OPC_CSRRx) | (opcode === `OPC_FENCE);
	wire typeSB_o = (opcode === `OPC_Bcc);
	wire typeS_o = (opcode === `OPC_Sx);

	wire src2_immediate_o = typeU_o;

	immpicker ip(
		.instruction_i(instruction_i),
		.typeI_i(typeI_o),
		.typeS_i(typeS_o),
		.typeSB_i(typeSB_o),
		.typeU_i(typeU_o),
		.typeUJ_i(typeUJ_o),
		.value_o(immediate_o)
	);
endmodule

// This logic exercises the instruction decoder.

module test_instruction_decoder();
	reg [15:0] story_o;
	reg [31:0] instruction_o;

	wire [63:0] immediate_i;
	wire src2_immediate_i;
	wire [4:0] rd_i;
	wire rd_we_i;

	instruction_decoder id(
		.instruction_i(instruction_o),
		.immediate_o(immediate_i),
		.src2_immediate_o(src2_immediate_i),
		.rd_o(rd_i),
		.rd_we_o(rd_we_i)
	);

	initial begin
		// LUI
		story_o <= 16'h0000;
		instruction_o <= 32'b10101010101010101010_11011_0110111;
		#20
		if(immediate_i !== 64'hFFFF_FFFF_AAAA_A000) begin
			$display("@E %04X Expected constant parameter of $FFFFFFFFAAAAA000; got $%016X", story_o, immediate_i);
			$stop;
		end
		if(src2_immediate_i !== 1) begin
			$display("@E %04X Expected EX-stage to use_immediate", story_o);
			$stop;
		end
		if(rd_i !== 5'b11011) begin
			$display("@E %04X Expected register 27; got %d", story_o, rd_i);
			$stop;
		end
		if(rd_we_i !== 1) begin
			$display("@E %04X Expected register write-back to be enabled.", story_o);
			$stop;
		end
		$display("@I Done.");
		$stop;
	end
endmodule

// TODO(sam-falvo):
//
// AUIPC		0010111		Rd := IP + imm20
// JAL			1101111		Rd := IP + 4; PC := disp21 + IP; flushPipe
// JALR			1100111		Rd := IP + 4; PC := Rs1 + imm12; flushPipe
// Bcc			1100011.ccc	IF Rs1 .op. Rs2 THEN PC := IP + disp13; flushPipe THEN
// Lx			0000011.xxx	Rd := MEMx(Rs1+imm12)
// Sx			0100011.xxx	MEMx(Rs1+imm12) := Rd
// aluI			0010011.fff	Rd := Rs1 .op. imm12
// alu			0110011.fff	Rd := Rs1 .op. Rs2
// FENCE		0001111		(no operation)
// FENCE.I		0001111		(no operation)
// CSRRx		1110011.0xx	(needs more thought; xx != 0)
// CSRRxI		1110011.1xx	(reuse logic from CSRRx; xx != 0)
