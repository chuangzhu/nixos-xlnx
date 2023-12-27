#!/usr/bin/env xsct
# Generate FSBL, PMUFW, device-tree from an XSA file
# This script should be ran using Xilinx Vitis xsct
# source /installation/path/to/Vitis/2022.2/settings64.sh
# xsct ./vitisgenfw.tcl <vivado_exported.xsa> [./output/directory/]

set xsa [lindex $argv 0]
if {[lindex $argv 1] != ""} {
	set outdir [lindex $argv 1]
} else {
	set outdir [file join [file dirname $xsa] firmware]
}
file mkdir $outdir

# https://wiki.tcl-lang.org/page/Creating+Temporary+Files
proc tmpdir {} {
	set chars abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789
	for {set i 0} {$i < 10} {incr i} {
		set path /tmp/tcl_
		for {set j 0} {$j < 10} {incr j} {
			append path [string index $chars [expr {int(rand() * 62)}]]
		}
		if {![file exists $path]} {
			file mkdir $path
			file attributes $path -permissions 0700
			return $path
		}
	}
	error {failed to find an unused temporary directory name}
}

if {![file exists ~/.cache/device-tree-xlnx]} {
	error "Clone https://github.com/Xilinx/device-tree-xlnx/ to ~/.cache/device-tree-xlnx!"
}

setws [tmpdir]

createdts -hw $xsa -platform-name devicetree -local-repo ~/.cache/device-tree-xlnx
set bspdir [file join [getws] devicetree psu_cortexa53_0 device_tree_domain bsp]
exec aarch64-linux-gnu-cpp -nostdinc -undef -x assembler-with-cpp $bspdir/system-top.dts -o $bspdir/system.dts
exec -ignorestderr dtc -@ -I dts -O dtb $bspdir/system.dts -o $bspdir/system.dtb
foreach dt {pcw.dtsi pl.dtsi zynqmp.dtsi system-top.dts system.dtb} {
	file copy -force $bspdir/$dt $outdir
}

app create -name fsbl -hw $xsa -os standalone -proc psu_cortexa53_0 -template {Zynq MP FSBL}
# app create -name pmufw -hw $xsa -os standalone -proc psu_pmu_0 -template {ZynqMP PMU Firmware}
app config -name fsbl define-compiler-symbols {FSBL_DEBUG_INFO}
app build -name fsbl
file copy -force [file join [getws] [file rootname $xsa] zynqmp_fsbl fsbl_a53.elf] $outdir
file copy -force [file join [getws] [file rootname $xsa] zynqmp_pmufw pmufw.elf] $outdir

file delete -force [getws]
