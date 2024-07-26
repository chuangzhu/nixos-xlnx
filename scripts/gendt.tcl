#!/usr/bin/env xsct

proc usage {} {
	puts "Generate device-tree and system-device-tree from an XSA file"
	puts "This script should be ran using Xilinx Vivado or Vitis xsct"
	puts ""
	puts "$ source /installation/path/to/Vivado/2024.1/settings64.sh"
	puts {$ xsct ./gendt.tcl -platform zynqmp <vivado_exported.xsa> [./output/directory/]}
}

for {set i 0} {$i < $argc} {incr i} {
	set arg [lindex $argv $i]
	if {$arg == "-help"} {
		usage
		exit 0
	} elseif {$arg == "-platform"} {
		incr i
		set platform [lindex $argv $i]
	} elseif {![info exists xsa]} {
		set xsa [lindex $argv $i]
	} elseif {![info exists outdir]} {
		set outdir [lindex $argv $i]
	}
}

if {![info exists xsa]} {
	puts "XSA file not specified!"
	exit 1
}
if {![info exists platform]} {
	puts "Platform not specified!"
	exit 1
}
if {![info exists outdir]} {
	set outdir [file join [file dirname $xsa] gendt]
}
file mkdir $outdir/dt $outdir/sdt
set xsabase [file rootname [file tail $xsa]]

if {$platform == "zynqmp"} {
	set arch "psu_cortexa53_0"
} elseif {$platform == "zynq"} {
	set arch "ps7_cortexa9_0"
} else {
	puts "Platform should be either zynq or zynqmp!"
}

if {![file exists $env(HOME)/.cache/device-tree-xlnx]} {
	puts "Please clone https://github.com/Xilinx/device-tree-xlnx/ to ~/.cache/device-tree-xlnx!"
	exit 2
}

# https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842279/Build+Device+Tree+Blob
hsi open_hw_design $xsa
hsi set_repo_path $env(HOME)/.cache/device-tree-xlnx
set procs [hsi get_cells -hier -filter {IP_TYPE==PROCESSOR}]
puts "List of processors found in XSA is $procs"
hsi create_sw_design device-tree -os device_tree -proc $arch
hsi generate_target -dir $outdir/dt
hsi close_hw_design [hsi current_hw_design]

sdtgen set_dt_param -xsa $xsa -dir $outdir/sdt
sdtgen generate_sdt
