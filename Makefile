SIM=iverilog -I rtl/verilog

.PHONY: test fetch xrs alu decode

test: fetch xrs alu decode

fetch:
	$(SIM) -Wall bench/verilog/fetch.v rtl/verilog/fetch.v
	vvp -n a.out

xrs:
	$(SIM) -Wall bench/verilog/xrs.v rtl/verilog/xrs.v
	vvp -n a.out

alu:
	$(SIM) -Wall bench/verilog/alu.v rtl/verilog/alu.v
	vvp -n a.out

decode: decode_op_imm

decode_op_imm:
	$(SIM) -Wall bench/verilog/decode_op_imm.v rtl/verilog/decode_op_imm.v
	vvp -n a.out
