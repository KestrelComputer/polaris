SIM=iverilog -I rtl/verilog

.PHONY: test polaris fetch xrs alu decode

test: polaris # fetch xrs alu decode

rtl/verilog/seq.v: rtl/SMG/seq.smg
	smg.shen rtl/SMG/seq.smg >rtl/verilog/seq.v

polaris: rtl/verilog/seq.v
	$(SIM) -Wall bench2/verilog/polaris.v rtl/verilog/polaris.v rtl/verilog/xrs.v rtl/verilog/seq.v rtl/verilog/alu.v
	vvp -n a.out

fetch:
	$(SIM) -Wall bench/verilog/fetch.v rtl/verilog/fetch.v
	vvp -n a.out

xrs:
	$(SIM) -Wall bench/verilog/xrs.v rtl/verilog/xrs.v
	vvp -n a.out

alu:
	$(SIM) -Wall bench/verilog/alu.v rtl/verilog/alu.v
	vvp -n a.out

decode:
	$(SIM) -Wall bench/verilog/decode.v rtl/verilog/decode.v
	vvp -n a.out
