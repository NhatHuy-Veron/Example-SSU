# Makefile for SSU UVM simulation
# Adapted from apb_uvm_github

TESTNAME    ?= ssu_test
TOP         ?= top_tb
RADIX       = hex

LOG_DIR     = log
WAVE_DIR    = waveform
DB_DIR      = db
COV_DIR     = coverage

all: clean build

build:
	@echo "[BUILD] Compiling design and testbench..."
	vlib work
	vmap work work
	vlog -sv +cover=bcesft +acc -f filelists.f +define+UVM_NO_DEPRECATED +define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR | tee compile.log

run:
	@echo "[SIM] Running UVM test: $(TESTNAME)"
	mkdir -p $(LOG_DIR) $(WAVE_DIR)
	vsim -c -voptargs="+acc" -assertdebug -l $(LOG_DIR)/$(TESTNAME).log $(TOP) \
	     -wlf $(WAVE_DIR)/$(TESTNAME).wlf \
	     -do "log -r /*; run -all; quit" \
	     +UVM_TESTNAME=$(TESTNAME) +UVM_TIMEOUT=1000000000,NO

run_cov:
	@echo "[SIM+COV] Running UVM test with coverage: $(TESTNAME)"
	mkdir -p $(LOG_DIR) $(WAVE_DIR) $(DB_DIR)
	vsim -coverage -c -voptargs="+cover=bcesft" -assertdebug -l $(LOG_DIR)/$(TESTNAME).log $(TOP) \
	     -wlf $(WAVE_DIR)/$(TESTNAME).wlf \
	     -do "if {[file exists exclude_coverage.tcl]} {do exclude_coverage.tcl}; coverage save -onexit ./$(DB_DIR)/$(TESTNAME).ucdb; log -r /*; run -all; quit" \
	     +UVM_TESTNAME=$(TESTNAME)

gen_cov:
	@echo "[COV] Generating merged coverage reports..."
	mkdir -p $(COV_DIR)
	vcover merge $(DB_DIR)/merged.ucdb $(DB_DIR)/*.ucdb
	vcover report $(DB_DIR)/merged.ucdb -output $(COV_DIR)/summary_report.txt
	vcover report -details -code bcesft -annotate -all -codeAll \
	              $(DB_DIR)/merged.ucdb -output $(COV_DIR)/detail_report.txt

wave:
	@if [ ! -f $(WAVE_DIR)/$(TESTNAME).wlf ]; then \
		echo "[WAVE] Waveform not found. Run 'make run TESTNAME=$(TESTNAME)' first."; \
	else \
		echo "[WAVE] Opening waveform viewer for test: $(TESTNAME)"; \
		vsim -i -view $(WAVE_DIR)/$(TESTNAME).wlf \
		     -do "add wave -r /*; radix -$(RADIX)" & \
	fi

clean:
	@echo "[CLEAN] Cleaning all generated files..."
	rm -rf *.ini work transcript *.dbg *.wlf \
	       $(LOG_DIR) $(WAVE_DIR) $(DB_DIR) $(COV_DIR)

.PHONY: all build run run_cov gen_cov wave clean