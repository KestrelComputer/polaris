SIM=iverilog -I rtl/verilog

.PHONY: test test_xprs test_alu

test: test_xprs test_alu

test_xprs: bench/verilog/xprs.v rtl/verilog/xprs.v
	$(SIM) bench/verilog/xprs.v rtl/verilog/xprs.v
	vvp -n a.out

test_alu: bench/verilog/alu.v rtl/verilog/alu.v
	$(SIM) bench/verilog/alu.v rtl/verilog/alu.v
	vvp -n a.out
