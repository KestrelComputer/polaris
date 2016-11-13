`timescale 1ns / 1ps

module computer(
`ifdef VERILATOR
	input clk,
	input reset
`endif
);
	wire iack;
	wire [63:0] iadr;
	wire istb;
	wire [11:0] cadr;
	wire coe, cwe;
	wire cvalid;
	wire [63:0] cdato, cdati;
	wire STB;
	wire [31:0] romQ;

`ifndef VERILATOR
	reg clk, reset;
	initial begin
		clk <= 0;
		reset <= 1;
		#60; reset <= 0;
	end

	always begin
		#20 clk <= ~clk;
	end
`endif

	PolarisCPU cpu(
		.fence_o(),
		.trap_o(),
		.cause_o(),
		.mepc_o(),
		.mpie_o(),
		.mie_o(),
		.ddat_o(),
		.dadr_o(),
		.dwe_o(),
		.dcyc_o(),
		.dstb_o(),
		.dsiz_o(),
		.dsigned_o(),
		.irq_i(1'b0),
		.iack_i(iack),
		.idat_i(romQ),
		.iadr_o(iadr),
		.istb_o(istb),
		.dack_i(1'b1),
		.ddat_i(64'h4141_4141_4141_4141),
		.cadr_o(cadr),
		.coe_o(coe),
		.cwe_o(cwe),
		.cvalid_i(cvalid),
		.cdat_o(cdato),
		.cdat_i(cdati),
		.clk_i(clk),
		.reset_i(reset)
	);

	rom rom(
		.A(iadr[11:2]),
		.Q(romQ),
		.STB(STB)
	);

	address_decode ad(
		.iadr_i(iadr[12]),
		.istb_i(istb),
		.iack_o(iack),
		.STB_o(STB)
	);

	output_csr outcsr(
		.cadr_i(cadr),
		.cvalid_o(cvalid),
		.cdat_o(cdati),
		.cdat_i(cdato),
		.coe_i(coe),
		.cwe_i(cwe),
		.clk_i(clk)
	);
endmodule

