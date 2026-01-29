## [20260124.ab3cf41]

[20260124.ab3cf41]: https://github.com/chuangzhu/nixos-xlnx/tree/ab3cf41e0af6485c39bc7b1535850d4d2605ddce

The default Nixpkgs pin is upgraded from `nixpkgs-unstable` [`20240719.1d9c2c9b3e71`](https://github.com/NixOS/nixpkgs/tree/1d9c2c9b3e71b9ee663d11c5d298727dace8d374) to [`nixos-25.11`](https://nixos.org/blog/announcements/2025/nixos-2511/). If you are not yet ready to upgrade, you can pin Nixpkgs back to commit `1d9c2c9b3e71`.

```diff
 {
   inputs.nixos-xlnx.url = "github:chuangzhu/nixos-xlnx";
+  inputs.nixpkgs.url = "github:NixOS/nixpkgs/1d9c2c9b3e71b9ee663d11c5d298727dace8d374";
+  inputs.nixos-xlnx.inputs.nixpkgs.follows = "nixpkgs";
```

Since nixos-24.11, you have to use `kernelModuleMakeFlags` instead of `kernel.makeFlags` in your own kernel modules:

```diff
 # module-name/derivation.nix
 
-{ lib, stdenv, kernel, kmod }:
+{ lib, stdenv, kernel, kmod, kernelModuleMakeFlags }:
 
 stdenv.mkDerivation {
   name = "module-name";
 
   src = ./.;
 
   hardeningDisable = [ "pic" ];
 
   nativeBuildInputs = kernel.moduleBuildDependencies ++ [ kmod ];
 
-  makeFlags = kernel.makeFlags ++ [
+  makeFlags = kernelModuleMakeFlags ++ [
     "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
   ];
   installFlags = [ "INSTALL_MOD_PATH=$(out)" ];
   installTargets = [ "modules_install" ];
 
   enableParallelBuilding = true;
 }
```

See NixOS/nixpkgs#376078 and NixOS/nixpkgs#377327.

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
