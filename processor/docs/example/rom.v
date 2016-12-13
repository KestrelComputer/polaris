`timescale 1ns / 1ps

module rom #(
	parameter bootrom_file = ""
)
(
	input	[11:3]	A,	// Address
	output	[63:0]	Q,	// Data output
	input	STB		// True if ROM is being accessed.
);
	reg [63:0] contents[0:511];
	wire [63:0] results = contents[A];
	assign Q = STB ? results : 0;

	initial begin
		$readmemh(bootrom_file, contents);
	end
endmodule

