#!/usr/bin/env -S vitis -s
# LD_LIBRARY_PATH=/installation/path/to/Vitis/2023.2/tps/lnx64/cmake-3.24.2/libs/Ubuntu ~/vitisgenfw/vitis2023genfw.py --platform zynqmp /path/to/your/system.xsa

import vitis
import datetime
import os
import argparse
import subprocess
import shutil
from pathlib import Path

argp = argparse.ArgumentParser()
argp.add_argument('--platform', required=True, choices=['zynq', 'zynqmp'])
argp.add_argument('xsa')
argp.add_argument('outdir', nargs='?', default=os.path.join('.', 'firmware'))
options = argp.parse_args()

now = datetime.datetime.now().strftime("%Y%m%d%I%M%S")
dt_workspace = f'/tmp/vitisgenfw_dt_{now}/'
fsbl_workspace = f'/tmp/vitisgenfw_fsbl_{now}/'
cachedir = os.environ.get('XDG_CACHE_HOME') or os.path.join(os.environ.get('HOME'), '.cache')
dtx_repo = os.path.join(cachedir, 'device-tree-xlnx')

# Device tree

if not os.path.exists(dtx_repo):
    print('Please clone https://github.com/Xilinx/device-tree-xlnx/ to ~/.cache/device-tree-xlnx!')
    os.sys.exit(2)

# https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842279/Build+Device+Tree+Blob
tcl = f"""
setws {dt_workspace}
hsi open_hw_design {options.xsa}
hsi set_repo_path {dtx_repo}
set procs [hsi get_cells -hier -filter {'{IP_TYPE==PROCESSOR}'}]
puts "List of processors found in XSA is $procs"
hsi create_sw_design device-tree -os device_tree -proc psu_cortexa53_0
hsi generate_target -dir {options.outdir}
hsi close_hw_design [hsi current_hw_design]
"""
os.mkdir(dt_workspace)
tclpath = os.path.join(dt_workspace, 'gendt.tcl')
with open(tclpath, 'w') as f:
    f.write(tcl)

subprocess.run(['xsct', tclpath])
shutil.rmtree(dt_workspace, ignore_errors=True)

subprocess.run(['aarch64-linux-gnu-cpp', '-nostdinc', '-undef', '-x', 'assembler-with-cpp',
                os.path.join(options.outdir, 'system-top.dts'), '-o', os.path.join(options.outdir, 'system.dts')])
subprocess.run(['dtc', '-@', '-I', 'dts', '-O', 'dtb',
                os.path.join(options.outdir, 'system.dts'), '-o', os.path.join(options.outdir, 'system.dtb')])

# FSBL, PMUFW

client = vitis.create_client()
client.set_workspace(fsbl_workspace)
platform_name = 'platform_fsbl'
platform = client.create_platform_component(name=platform_name, hw=options.xsa, cpu='psu_cortexa53_0')
platform.retarget_fsbl(target_processor='psu_cortexa53_0')
platform.build()

# platform.add_domain(name='standalone_a53_0', cpu='psu_cortexa53_1', os='standalone')
# standalone_a53_0 = platform.get_domain(name='standalone_a53_0')
# standalone_a53_0.regenerate()

shutil.copy(os.path.join(fsbl_workspace, platform_name, 'zynqmp_fsbl', 'build', 'fsbl.elf'),
            os.path.join(options.outdir, 'fsbl_a53.elf'))
shutil.copy(os.path.join(fsbl_workspace, platform_name, 'zynqmp_pmufw', 'build', 'pmufw.elf'), options.outdir)
shutil.copy(os.path.join(fsbl_workspace, platform_name, 'hw', 'sdt', Path(options.xsa).stem) + '.bit',
            os.path.join(options.outdir, 'system.bit'))

# platform.remove_boot_bsp()
# client.delete_platform_component(platform_name)
# shutil.rmtree(fsbl_workspace, ignore_errors=True)

vitis.dispose()
