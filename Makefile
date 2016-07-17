SIM=iverilog -I rtl/verilog

.PHONY: test fetch

test: fetch

fetch:
	$(SIM) -Wall bench/verilog/fetch.v rtl/verilog/fetch.v
	vvp -n a.out
