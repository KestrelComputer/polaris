SIM=iverilog -I rtl/verilog

.PHONY: test test_xprs test_alu test_immpicker test_instruction_decoder test_stage_f test_stage_d test_stage_m

test: test_xprs test_alu test_immpicker test_instruction_decoder test_stage_f test_stage_d test_stage_m

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

test_stage_f: bench/verilog/stage_f.v rtl/verilog/stage_f.v
	$(SIM) bench/verilog/stage_f.v rtl/verilog/stage_f.v
	vvp -n a.out

test_stage_d: bench/verilog/stage_d.v # rtl/verilog/stage_d.v
	$(SIM) bench/verilog/stage_d.v # rtl/verilog/stage_d.v
	vvp -n a.out

test_stage_m: bench/verilog/stage_m.v rtl/verilog/stage_m.v
	$(SIM) bench/verilog/stage_m.v rtl/verilog/stage_m.v
	vvp -n a.out
