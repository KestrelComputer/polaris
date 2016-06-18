`timescale 1ns / 1ps

// This exercises logic designed to take an instruction and extract useful
// immediate constants out it.

module test_immpicker();
	reg [15:0] story_o;
	reg [31:0] ir_o;
	reg typeI_o;
	reg typeS_o;
	reg typeSB_o;
	reg typeU_o;
	reg typeUJ_o;

	wire [63:0] value_i;

	immpicker i(
		.instruction_i(ir_o),
		.value_o(value_i),
		.typeI_i(typeI_o),
		.typeS_i(typeS_o),
		.typeSB_i(typeSB_o),
		.typeU_i(typeU_o),
		.typeUJ_i(typeUJ_o)
	);

	task chkimm;
	input [15:0] story;
	input [31:0] instr;
	input [63:0] expData;
	input typeI, typeS, typeSB, typeU, typeUJ;
	begin
		story_o <= story;
		ir_o <= instr;
		typeI_o <= typeI;
		typeS_o <= typeS;
		typeSB_o <= typeSB;
		typeU_o <= typeU;
		typeUJ_o <= typeUJ;
		#20
		if(value_i !== expData) begin
			$display("@E %04X Expected value %016X, got %016X", story_o, expData, value_i);
			$stop;
		end
	end
	endtask

	initial begin
		chkimm(16'h0000, 32'b010101010101_11111_111_11111_1111111, 64'h0000_0000_0000_0555, 1, 0, 0, 0, 0);
		chkimm(16'h0001, 32'b101010101010_11111_111_11111_1111111, 64'hFFFF_FFFF_FFFF_FAAA, 1, 0, 0, 0, 0);
		chkimm(16'h0100, 32'b0101010_11111_11111_111_10101_1111111, 64'h0000_0000_0000_0555, 0, 1, 0, 0, 0);
		chkimm(16'h0101, 32'b1010101_11111_11111_111_01010_1111111, 64'hFFFF_FFFF_FFFF_FAAA, 0, 1, 0, 0, 0);
		chkimm(16'h0200, 32'b0101010_11111_11111_111_10101_1111111, 64'h0000_0000_0000_0D54, 0, 0, 1, 0, 0);
		chkimm(16'h0201, 32'b1010101_11111_11111_111_01010_1111111, 64'hFFFF_FFFF_FFFF_F2AA, 0, 0, 1, 0, 0);
		chkimm(16'h0300, 32'b01010101010101010101_11111_1111111, 64'h0000_0000_5555_5000, 0, 0, 0, 1, 0);
		chkimm(16'h0301, 32'b10101010101010101010_11111_1111111, 64'hFFFF_FFFF_AAAA_A000, 0, 0, 0, 1, 0);
		chkimm(16'h0400, 32'b01010101010101010101_11111_1111111, 64'h0000_0000_0005_5D54, 0, 0, 0, 0, 1);
		chkimm(16'h0401, 32'b10101010101010101010_11111_1111111, 64'hFFFF_FFFF_FFFA_A2AA, 0, 0, 0, 0, 1);

		chkimm(16'h0401, 32'b11111111111111111111111111111111, 64'h0000_0000_0000_0000, 0, 0, 0, 0, 0);

		$display("@I Done");
		$stop;
	end
endmodule

