SIM=iverilog -I rtl/verilog
SMG=smg.shen

.PHONY: test bottleneck

test: bottleneck

bottleneck: bench/verilog/bottleneck.v rtl/verilog/bottleneck.v rtl/verilog/bottleneckSequencer.v
	$(SIM) -Wall bench/verilog/bottleneck.v rtl/verilog/bottleneck.v rtl/verilog/bottleneckSequencer.v
	vvp -n a.out

rtl/verilog/bottleneckSequencer.v: rtl/SMG/seq.smg
	$(SMG) rtl/SMG/seq.smg >rtl/verilog/bottleneckSequencer.v
