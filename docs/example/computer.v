`timescale 1ns / 1ps

module computer();
	reg clk, reset;

	wire iack;
	wire [63:0] iadr;
	wire istb;
	wire [11:0] cadr;
	wire coe, cwe;
	wire cvalid;
	wire [63:0] cdato, cdati;
	wire STB;
	wire [31:0] romQ;

	always begin
		#20 clk <= ~clk;
	end

	initial begin
$dumpfile("wtf.vcd");
$dumpvars;
		clk <= 0;
		reset <= 1;
		wait(clk); wait(~clk);
		wait(clk); wait(~clk);
		wait(clk); wait(~clk);
		reset <= 0;
$monitor("%d %d %016X %0X", $time, clk, cpu.iadr_o, rom.A);
	end

	PolarisCPU cpu(
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

	rom_module rom(
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

