#!/usr/bin/env xsct

proc usage {} {
	puts "Generate bitstream, FSBL, PMUFW, device-tree from an XSA file"
	puts "This script should be ran using Xilinx Vitis xsct"
	puts ""
	puts "$ source /installation/path/to/Vitis/2022.2/settings64.sh"
	puts {$ xsct ./vitisgenfw.tcl -platform zynqmp <vivado_exported.xsa> [./output/directory/]}
}

for {set i 0} {$i < $argc} {incr i} {
	set arg [lindex $argv $i]
	if {$arg == "-help"} {
		usage
		exit 0
	} elseif {$arg == "-target"} {
		incr i
		set target [lindex $argv $i]
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
	set outdir [file join [file dirname $xsa] firmware]
}
file mkdir $outdir
set xsabase [file rootname [file tail $xsa]]

if {$platform == "zynqmp"} {
	set arch "psu_cortexa53_0"
	set template "Zynq MP FSBL"
	set dtfile {pcw.dtsi pl.dtsi zynqmp.dtsi zynqmp-clk-ccf.dtsi system-top.dts system.dtb}
} elseif {$platform == "zynq"} {
	set arch "ps7_cortexa9_0"
	set template "Zynq FSBL"
	set dtfile {pcw.dtsi skeleton.dtsi zynq-7000.dtsi system-top.dts system.dtb}
} else {
	puts "Platform should be either zynq or zynqmp!"
}

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
	puts "Please clone https://github.com/Xilinx/device-tree-xlnx/ to ~/.cache/device-tree-xlnx!"
	exit 2
}

if {![info exists target]} {

	exec xsct $argv0 -target "devicetree" -platform $platform $xsa $outdir >@stdout 2>@stderr
	exec xsct $argv0 -target "fsbl" -platform $platform $xsa $outdir >@stdout 2>@stderr

} elseif {$target == "devicetree"} {

	setws [tmpdir]

	createdts -hw $xsa -platform-name devicetree -local-repo ~/.cache/device-tree-xlnx
	file copy -force [file join [getws] devicetree hw $xsabase.bit] $outdir/system.bit

	set bspdir [file join [getws] devicetree $arch device_tree_domain bsp]
	exec aarch64-linux-gnu-cpp -nostdinc -undef -x assembler-with-cpp $bspdir/system-top.dts -o $bspdir/system.dts
	exec -ignorestderr dtc -@ -I dts -O dtb $bspdir/system.dts -o $bspdir/system.dtb
	foreach dt $dtfile {
		file copy -force $bspdir/$dt $outdir
	}

	file delete -force [getws]

} elseif {$target == "fsbl"} {

	setws [tmpdir]

	app create -name fsbl -hw $xsa -os standalone -proc $arch -template $template
	# app create -name pmufw -hw $xsa -os standalone -proc psu_pmu_0 -template {ZynqMP PMU Firmware}
	app config -name fsbl define-compiler-symbols {FSBL_DEBUG_INFO}
	app build -name fsbl
	if {$platform == "zynqmp"} {
		file copy -force [file join [getws] $xsabase zynqmp_fsbl fsbl_a53.elf] $outdir
		file copy -force [file join [getws] $xsabase zynqmp_pmufw pmufw.elf] $outdir
	} else {
		file copy -force [file join [getws] $xsabase zynq_fsbl fsbl.elf] $outdir
	}

	file delete -force [getws]

}
