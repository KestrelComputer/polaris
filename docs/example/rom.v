`timescale 1ns / 1ps

module rom(
	input	[11:2]	A,	// Address
	output	[31:0]	Q,	// Data output
	input	STB		// True if ROM is being accessed.
);
	reg [31:0] contents[0:1023];
	wire [31:0] results = contents[A];
	assign Q = STB ? results : 0;

	initial begin
		$readmemh("example.hex", contents);
	end
endmodule

