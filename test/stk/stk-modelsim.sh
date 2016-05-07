#!/bin/bash

#Remove all files from rtl_work
# if {[file exists rtl_work]} {
# 	vdel -lib rtl_work -all
# }

# Create libraries (each creates a corresponding empty folder)
vlib rtl_work
vmap work rtl_work

#Compile vhdl (note that all flags are optional here)
vlog -sv -work work +incdir+./ Chip8_Stack.sv
vlog -sv -work work +incdir+./ stack_testbench.sv
#Without -work it compiles in library work

#Run the simulation (assumes top module is compiled in library work)
vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  stack_testbench -do "run 10000ns"

# run 10000ns
#Run a more complex simulation
# vsim -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs=\"+acc\" -t 1ps stk_testbench 

# -L links an external precompiled library; In this case I'm linking all xilinx components.
# -g<CONSTANT>=<value> overrides VHDL top level entity generic default value
# -t <timescale> sets the default timescale
# -novopt disables optimizations to keep all signals visible, even if unused
# +notimingchecks disables timing checks embedded in the behavioral models of the standard cells (or FPGA in this case) libraries
# -do <script> runs a modelsim script right after starting the simulation
# -do "<command>" runs the specified command right after starting the simulation
