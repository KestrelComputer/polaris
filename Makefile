SIM=iverilog -I rtl/verilog

.PHONY: test test_xprs test_alu test_immpicker test_instruction_decoder

test: test_xprs test_alu test_immpicker test_instruction_decoder

test_xprs: bench/verilog/xprs.v rtl/verilog/xprs.v
	$(SIM) bench/verilog/xprs.v rtl/verilog/xprs.v
	vvp -n a.out

test_alu: bench/verilog/alu.v rtl/verilog/alu.v
	$(SIM) bench/verilog/alu.v rtl/verilog/alu.v
	vvp -n a.out

test_immpicker: bench/verilog/immpicker.v rtl/verilog/immpicker.v
	$(SIM) bench/verilog/immpicker.v rtl/verilog/immpicker.v
	vvp -n a.out

test_instruction_decoder: bench/verilog/instruction_decoder.v rtl/verilog/immpicker.v
	$(SIM) bench/verilog/instruction_decoder.v rtl/verilog/immpicker.v
	vvp -n a.out
