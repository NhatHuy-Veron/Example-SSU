# File list for SSU UVM simulation
# Include directories
+incdir+../tb
+incdir+../tb/agents
+incdir+../tb/env
+incdir+../tb/seq
+incdir+../tb/tests

# UVM library (if needed, uncomment and set correct path)
# +incdir+/path/to/uvm/src
# -L uvm

# RTL files
../rtl/ssu.sv

# Interface file
../tb/ssu_if.sv

# Package file
../tb/ssu_pkg.sv

# Testbench file
../tb/top_tb.sv