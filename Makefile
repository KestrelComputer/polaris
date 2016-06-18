.PHONY: test test_xprs

test: test_xprs
	echo "Hi."

test_xprs:
	iverilog bench/verilog/xprs.v
	vvp -n a.out

