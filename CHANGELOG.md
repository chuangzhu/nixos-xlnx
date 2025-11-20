## [20250825.932f475]

[20250825.932f475]: https://github.com/chuangzhu/nixos-xlnx/tree/932f47584b39a8a0b86863718f5ba9f1fd8e9ce5

Vivado 2025.1 support is added to the master branch. To support multiple Vivado versions on the same branch, a new NixOS option `hardware.zynq.xlnxVersion` is added. Currently it can be `2024.1` or `2025.1`.

```diff
 hardware.zynq = {
+  xlnxVersion = "2024.1";  # Or "2025.1"
   platform = "zynqmp";  # Or "zynq" for Zynq 7000
   bitstream = ./output/directory/sdt/vivado_exported.bit;
   sdtDir = ./output/directory/sdt;
   dtDir = ./output/directory/dt;
 };
```

## [20240721.ec29a0c]

[20240721.ec29a0c]: https://github.com/chuangzhu/nixos-xlnx/tree/ec29a0c32c6e1594a9433936fa1390d61031d54c

Since Vivado 2024.1\*, FSBL and PMUFW can be built from source using the system-device-tree flow. However, system-device-tree and device-tree generation from XSA still requires Vivado HSI to work. You need to run [`scripts/gendt.tcl`](./scripts/gendt.tcl) in XSCT to do that.

Nothing stops you from keep using the proprietary Vitis flow though, but the SDT flow is generally cleaner and I highly recommend you to use it.

Previous:

```bash
source /installation/path/to/Vitis/2022.2/settings64.sh
xsct ./vitisgenfw.tcl vivado_exported.xsa ./output/directory/ -platform zynqmp  # Or "zynq" for Zynq 7000
```

```nix
hardware.zynq = {
  platform = "zynqmp";  # Or "zynq" for Zynq 7000
  bitstream = ./output/directory/system.bit;
  fsbl = ./output/directory/fsbl_a53.elf;
  pmufw = ./output/directory/pmufw.elf;  # Remove for Zynq 7000
  dtb = ./output/directory/system.dtb;
};
```

After:

```bash
source /installation/path/to/Vivado/2024.1/settings64.sh
./scripts/gendt.tcl vivado_exported.xsa ./output/directory/ -platform zynqmp  # Or "zynq" for Zynq 7000
```

```nix
hardware.zynq = {
  platform = "zynqmp";  # Or "zynq" for Zynq 7000
  bitstream = ./output/directory/sdt/vivado_exported.bit;
  sdtDir = ./output/directory/sdt;
  dtDir = ./output/directory/dt;
};
```

\*: Actually system-device-tree flow is added in Vivado 2023.2. But it contains bugs and does not boot.
