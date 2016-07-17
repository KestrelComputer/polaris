`timescale 1ns / 1ps

// The fetch module is responsible for managing instruction fetch operations.
// This implies it must also deal with external interrupts as well as
// internally generated traps.

module fetch(
	input		[15:0]	dat_i,
	input		[63:2]	csr_mtvec_i,
	input			ack_i,
	input			clk_i,
	input			defined_i,
	input			pause_i,
	input			reset_i,
	output		[1:0]	size_o,
	output reg	[31:0]	ir_o,
	output		[63:0]	adr_o,
	output			mpie_mie_o,
	output			mie_0_o,
	output			mcause_2_o
);
	// We multiplex all the different sources of addresses onto this
	// address bus.  Sometimes, we'll need to pad bits to make things
	// line up right.

	assign adr_o =
		(ADR_NPC) ? {r_npc, 2'b00} :
		(ADR_NPCp2) ? {r_npc, 2'b10} :
		(ADR_MTVEC) ? {csr_mtvec_i, 2'b00} :
		64'd0;

	// The instruction fetcher needs to know from where to fetch the next
	// instruction.  This is the purpose of the NPC register.

	reg [63:2] r_npc;

	// The SIZE_O bus indicates how big the transfer size is, and
	// how many data bits of the input data bus are going to be used.
	// The meanings are:
	//
	//	00	No bus cycle in progress.
	//	01	One byte is expected to appear on DAT_I[7:0]
	//	10	Two bytes are expected to appear on DAT_I[15:0]
	//	11	Unused; must never appear.

	assign size_o =
		(SIZE_2) ? 2'b10 :
		2'b00;

	// The instruction fetcher is a self-contained state machine.
	// Some of the bits that determines the current state comes from
	// a register called state.  Others are taken as inputs from other
	// parts of the computer.  At present, there are 14 different states.

	reg [2:0] state;

	wire s0 = state == 3'b000;
	wire s1 = state == 3'b001;
	wire s2 = state == 3'b010;
	wire s3 = state == 3'b011;
	wire s4 = state == 3'b100;
	wire s5 = state == 3'b101;

	// This term discovers undefined or illegal instructions, and kicks off
	// an illegal instruction trap.

	wire fire0 = (~reset_i) & (~defined_i) & s0;

	// This term discovers when an instruction needs to postpone an
	// instruction fetch for some reason.  Note that pause_i MUST be
	// asserted during state 0 for it to have this meaning.

	wire fire1 = (~reset_i) & defined_i & pause_i & s0;

	// This term kicks off the first of two instruction fetch transactions.
	// This sets up the address bus for the low halfword of the next
	// instruction.

	wire fire2 = (~reset_i) & defined_i & (~pause_i) & s0;

	// This term waits for ACK_I to be asserted.  NOTE: This term DOES NOT
	// stall the instruction execute unit.

	wire fire3 = (~reset_i) & (~ack_i) & s1;

	// This term fires when ACK_I is asserted, thus causing data on DAT_I
	// to be registered into IRL.

	wire fire4 = (~reset_i) & ack_i & s1;

	// This term is just like S0, except for the upper halfword of the next
	// instruction.

	wire fire5 = (~reset_i) & s2;

	// This term is just like S1, except for the upper halfword of the next
	// instruction.  Again, this term does not stall the instruction
	// execute unit.

	wire fire6 = (~reset_i) & (~ack_i) & s3;

	// This term fires when the instruction fetch operation completes.  We
	// have the high halfword of the next instruction on the data bus, and
	// we're ready to load the IR.
	//
	// When this term fires, we know the instruction fetched is ready to
	// hand off to the execute unit.  Thus, IR is set to DAT_I : IRL.  IRH
	// is not used.

	wire fire7 = (~reset_i) & (~pause_i) & ack_i & s3;

	// This term fires when we've completed pre-fetching the next instruction,
	// but we haven't finished the current instruction yet.  Thus, this state
	// is reached when we are just starting to wait for the completion of the
	// current instruction.

	wire fire8 = (~reset_i) & pause_i & ack_i & s3;

	// This term fires, and keeps firing, until pause_i is asserted, but
	// only if it has been asserted late in the instruction fetch cycle.
	// This allows the instruction fetch unit to continue fetching the next
	// instruction, and to sleep until the execute unit says it's OK to
	// dispatch the next instruction.

	wire fire9 = (~reset_i) & pause_i & s4;

	// When pause_i finally negates, this state is responsible for loading
	// the IR with IRH:IRL, and restoring normal state machine operation.

	wire fire10 = (~reset_i) & (~pause_i) & s4;

	// These rules fire for similar reasons, but only when pause_i is
	// asserted early in the instruction fetch cycle.  This allows the
	// current instruction to postpone fetching the next instruction (maybe
	// because we don't yet know the correct value of NPC, as with
	// conditional branches).

	wire fire11 = (~reset_i) & pause_i & s5;
	wire fire12 = (~reset_i) & (~pause_i) & s5;

	// Depending on which state case is firing at the moment,
	// we want to set our next state in a sensible way.

	wire [2:0] next_state =
		(fire0 | fire2 | fire3) ? 1 :
		(fire4) ? 2 :
		(fire5 | fire6) ? 3 :
		(fire8 | fire9) ? 4 :
		(fire1 | fire11) ? 5 :
		(reset_i) ? 6 :		// Any unused state will work
		0;

always @(posedge clk_i or negedge clk_i) begin
#6 $display("C%d ST=%d NS=%d F=%12b R%d D%d P%d A%d I%d H$%04X L$%04X HD%d LD%D", clk_i, state, next_state, {fire0, fire1, fire2, fire3, fire4,fire5,fire6,fire7,fire8,fire9,fire10,fire11,fire12}, reset_i, defined_i, pause_i, ack_i, IR_DAT_IRL, irh, irl, IRH_DAT, IRL_DAT);
end

	// We only want to apply the low halfword instruction address when
	// fetching the low halfword of the next opcode.  Similarly, we
	// only want to ask for the high halfword when we're ready.

	wire ADR_NPC = fire2 | fire3 | fire4;
	wire ADR_NPCp2 = |{fire5, fire6, fire7, fire8};
	wire is_opcode_fetch = |{fire0, fire2, fire3, fire4, fire5, fire6, fire7, fire8};
	wire SIZE_2 = is_opcode_fetch;
	wire VPA_O = is_opcode_fetch;

	// If we hit an undefined instruction, we want to take the exception.

	wire ADR_MTVEC = fire0;
	wire NPC_MTVEC = fire0;

	// Whenever we handle an exception, we must set MEPC to either the CPC
	// or to the NPC, depending on the nature of the exception.

	wire MEPC_CPC = fire0;

	// For every exception, we enter machine-mode, and that means turning
	// off machine-mode interrupts.  We also need to preserve the previous
	// setting.

	wire mpie_mie_o = fire0;
	wire mie_0_o = fire0;

	// Every exception has a cause.  This logic figures out what it is.

	wire mcause_2_o = fire0;

	// We fetch instructions in two halfwords, to accomodate the 16-bit
	// external bus.  Eventually, these two parts will make it to the
	// actual instruction register (IR).

	reg [15:0] irl;
	reg [15:0] irh;

	// We trigger updates to IRL and IRH only at the appropriate times.
	// Note that we can also optimize out one cycle if we recognize when
	// we can bypass the loading of IRH.

	wire IRL_DAT = fire4;
	wire IRH_DAT = fire7 | fire8;
	wire IR_DAT_IRL = fire7 | fire10;
	wire CPC_NPC = IR_DAT_IRL;
	wire NPC_NPCp4 = CPC_NPC;

	// Our next program counter value can take on one of a number of values
	// for a given cycle.

	wire [63:2] next_npc =
		(reset_i) ? 62'h3FFF_FFFF_FFFF_FFC0 :
		(NPC_NPCp4) ? r_npc+1 :
		(NPC_MTVEC) ? csr_mtvec_i :
		r_npc;

	// Polaris is capable of fetching the next instruction while processing
	// another.  Since we don't want to overwrite the IR contents while
	// processing, IRL is used to temporarily hold the low halfword of the
	// next instruction.

	wire [15:0] next_irl =
		(reset_i) ? 16'h0013 :
		(IRL_DAT) ? dat_i :
		irl;

	// Normally, the CPU can get by with just the IRL register.  Sometimes,
	// particularly when processing a memory-store instruction, we need to
	// cache the upper halfword of the next instruction.  That's IRH's job.

	wire [15:0] next_irh =
		(reset_i) ? 16'h0000 :
		(IRH_DAT) ? dat_i :
		irh;

	// The instruction register (IR) is used to hold the instruction being
	// currently executed.  On hard reset, we default it to the canonical
	// NOP instruction (ADDI X0, X0, 0).

	wire [31:0] next_ir =
		(reset_i) ? 32'h00000013 :
		(IR_DAT_IRL) ? {dat_i, irl} :
		ir;

	always @(posedge clk_i) begin
		irl <= next_irl;
		irh <= next_irh;
		ir_o <= next_ir;
		r_npc <= next_npc;
		state <= next_state;
	end
endmodule

// Exercise the instruction fetch module.

module test_fetch();
	reg [15:0] dat_o;
	reg [15:0] story_o;
	reg ack_o;
	reg clk_o;
	reg defined_o;
	reg pause_o;
	reg reset_o;
	reg [63:2] csr_mtvec_o;
	wire [1:0] size_i;
	wire [31:0] ir_i;
	wire [63:0] adr_i;
	wire mpie_mie_i;
	wire mie_0_i;
	wire mcause_2_i;

	fetch f(
		.ack_i(ack_o),
		.adr_o(adr_i),
		.clk_i(clk_o),
		.reset_i(reset_o),
		.size_o(size_i),
		.dat_i(dat_o),
		.defined_i(defined_o),
		.pause_i(pause_o),
		.ir_o(ir_i),
		.csr_mtvec_i(csr_mtvec_o),
		.mpie_mie_o(mpie_mie_i),
		.mie_0_o(mie_0_i),
		.mcause_2_o(mcause_2_i)
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

	task assert_adr;
	input [63:0] expected;
	begin
		if(adr_i !== expected) begin
			$display("@E %04X ADR_O Expected=%016X Got=%016X", story_o, expected, adr_i);
			$stop;
		end
	end
	endtask

	task assert_ir;
	input [31:0] expected;
	begin
		if(ir_i !== expected) begin
			$display("@E %04X IR_I Expected=%08X Got=%08X", story_o, expected, ir_i);
			$stop;
		end
	end
	endtask

	task assert_size;
	input [1:0] expected;
	begin
		if(size_i !== expected) begin
			$display("@E %04X SIZE_O Expected=%d Got=%d", story_o, expected, size_i);
			$stop;
		end
	end
	endtask

	task assert_mpie_mie;
	input expected;
	begin
		if(mpie_mie_i !== expected) begin
			$display("@E %04X MPIE_MIE_O Expected=%d Got=%d", story_o, expected, mpie_mie_i);
			$stop;
		end
	end
	endtask

	task assert_mie_0;
	input expected;
	begin
		if(mie_0_i !== expected) begin
			$display("@E %04X MIE_0_O Expected=%d Got=%d", story_o, expected, mie_0_i);
			$stop;
		end
	end
	endtask

	task assert_mcause_2;
	input expected;
	begin
		if(mcause_2_i !== expected) begin
			$display("@E %04X MCAUSE_2_O Expected=%d Got=%d", story_o, expected, mcause_2_i);
			$stop;
		end
	end
	endtask

	initial begin
		clk_o <= 0;
		reset_o <= 0;
		ack_o <= 0;
		defined_o <= 1;
		pause_o <= 0;
		csr_mtvec_o <= 62'b01110111011101110111011101110111011101110111011101110111011101;
		tick(16'hFFFF);

		// When the CPU is reset, the bus must be idle.
		reset_o <= 1;
		tick(16'h0000);
		assert_size(0);
		tick(16'h0001);
		assert_size(0);

		// When the CPU comes out of reset, we expect the instruction
		// at $FFFFFFFFFFFFFF00 to be fetched.  This will take a total
		// of four clock cycles, assuming ACK_I is asserted the whole
		// time.

		reset_o <= 1;
		tick(16'h01FF);

		reset_o <= 0;
		ack_o <= 1;
		tick(16'h0100);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);

		dat_o <= 16'hAAAA;
		tick(16'h0101);
		assert_adr(64'hFFFFFFFFFFFFFF00);
		assert_size(2);

		tick(16'h0102);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);

		dat_o <= 16'hBBBB;
		tick(16'h0103);
		assert_adr(64'hFFFFFFFFFFFFFF02);
		assert_size(2);

		tick(16'h0110);
		assert_adr(64'hFFFFFFFFFFFFFF04);
		assert_ir(32'hBBBBAAAA);

		// When fetching an illegal instruction, the CPU must dispatch
		// to the illegal instruction trap handler.

		assert_mpie_mie(0);
		assert_mie_0(0);
		assert_mcause_2(0);
		defined_o <= 0;
		#1;	// Give the processor some time to notice the instruction is illegal.
		assert_mpie_mie(1);
		assert_mie_0(1);
		assert_mcause_2(1);
		tick(16'h0201);
		assert_adr(64'h7777777777777774);
		assert_mpie_mie(0);
		assert_mie_0(0);
		assert_mcause_2(0);
		dat_o <= 16'hCCCC;

		tick(16'h0202);
		tick(16'h0203);
		dat_o <= 16'hDDDD;

		tick(16'h0210);
		defined_o <= 1;
		#1;	// Give the processor some time to decode the "legal" instruction.
		assert_ir(32'hDDDDCCCC);
		assert_adr(64'h7777777777777778);

		$display("@DONE");
		$stop;
	end
endmodule

