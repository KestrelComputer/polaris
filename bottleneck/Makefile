SIM=iverilog -I rtl/verilog

.PHONY: test bottleneck

test: bottleneck

bottleneck: bench/verilog/bottleneck.v rtl/verilog/bottleneck.v
	$(SIM) -Wall bench/verilog/bottleneck.v rtl/verilog/bottleneck.v
	vvp -n a.out
