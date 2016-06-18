.PHONY: test test_xprs

test: test_xprs

test_xprs: bench/verilog/xprs.v rtl/verilog/xprs.v
	iverilog bench/verilog/xprs.v rtl/verilog/xprs.v
	vvp -n a.out
