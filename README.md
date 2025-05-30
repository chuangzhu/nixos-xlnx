# nixos-xlnx

NixOS and Nix packages for Xilinx Zynq 7000 SoCs and Zynq UltraScale+ MPSoCs. It's like PetaLinux, but instead of Yocto/OpenEmbedded/BitBake, it uses NixOS/Nixpkgs/Nix. Currently it targets Vivado 2024.1 and Nixpkgs unstable.

This project isn't considered stable yet. Options may change anytime without noticing. Pin your inputs!

## Limitations

Since Vivado v2024.1, FSBL and PMUFW can be built from source using the system-device-tree flow. However, system-device-tree and device-tree generation from XSA still requires Vivado HSI to work. You need to run [`scripts/gendt.tcl`](./scripts/gendt.tcl) in XSCT to do that.

## Build SD card images

After finishing your hardware design in Vivado, choose `File > Export > Export Hardware...`. Make sure you selected `Include bitstream`. Save the XSA file. Run [`scripts/gendt.tcl`](./scripts/gendt.tcl) to generate the device-tree and system-device-tree:

```bash
git clone https://github.com/Xilinx/device-tree-xlnx ~/.cache/device-tree-xlnx -b xilinx_v2024.1 --depth 1
source /installation/path/to/Vivado/2024.1/settings64.sh
./scripts/gendt.tcl vivado_exported.xsa ./output/directory/ -platform zynqmp  # Or "zynq" for Zynq 7000
```

Assuming you have [Nix flakes](https://wiki.nixos.org/wiki/Flakes) enabled, configure NixOS as follows:

```nix
{
  inputs.nixos-xlnx.url = "github:chuangzhu/nixos-xlnx";

  outputs = { self, nixos-xlnx }: {
    nixosConfigurations.zynqmpboard = nixos-xlnx.inputs.nixpkgs.lib.nixosSystem {
      modules = [
        nixos-xlnx.nixosModules.sd-image

        ({ pkgs, lib, config, ... }: {
          nixpkgs.hostPlatform = "aarch64-linux";  # Or "armv7l-linux" for Zynq 7000
          # nixpkgs.buildPlatform = "x86_64-linux";
          hardware.zynq = {
            platform = "zynqmp";  # Or "zynq" for Zynq 7000
            bitstream = ./output/directory/sdt/vivado_exported.bit;
            sdtDir = ./output/directory/sdt;
            dtDir = ./output/directory/dt;
          };
          hardware.deviceTree.overlays = [
            { name = "system-user"; dtsFile = ./system-user.dts; }
          ];
          users.users.root.initialPassword = "INSECURE CHANGE ME LATER";
          services.openssh = {
            enable = true;
            settings.PermitRootLogin = "yes";
          };
          # If zfs-kernel fails to build, add this line to exclude ZFS support
          boot.supportedFilesystems = lib.mkForce [ "btrfs" "reiserfs" "vfat" "f2fs" "xfs" "ntfs" "cifs" ];
          # ... Other NixOS configurations
        })

      ];
    };
  };
}
```

Vivado only knows your PL/PS configuration *inside the SoC*. Therefore, the generated device-tree may not suit your *board* configuration. If you used PetaLinux before, you know that frequently you need to override properties, add/delete nodes with DTSIs in a special directory. In NixOS, we use device-tree overlays for that. Note that overlay DTSs are slightly different with a regular DTS:

```c
/dts-v1/;
/plugin/;  // Required
/ { compatible = "xlnx,zynqmp"; };  // Required, or "xlnx,zynq-7000"
// ... Your overrides
```

```bash
nix build .#nixosConfigurations.zynqmpboard.config.system.build.sdImage -vL
zstdcat ./result/nixos-sd-image-24.05.20231222.6df37dc-aarch64-linux.img.zst | sudo dd of=/dev/mmcblk0 status=progress
```

## Deploy to running systems

When you make changes to your configuration, you don't have to rebuild and reflash the SD card image. The rootfs (including kernel, device-tree) can be updated using:

```bash
out=$(nix build --no-link --print-out-paths -vL .#nixosConfigurations.zynqmpboard.config.system.build.toplevel)
nix copy --no-check-sigs --to "ssh://root@zynqmpboard.local" "$out"
ssh root@zynqmpboard.local nix-env -p /nix/var/nix/profiles/system --set $out
ssh root@zynqmpboard.local /nix/var/nix/profiles/system/bin/switch-to-configuration switch
```

After that, you can update BOOT.BIN using

```bash
ssh root@zynqmpboard.local xlnx-firmware-update
```

## Notes on cross compilation

* For ZynqMP, Nixpkgs provides tons of prebuilt packages for aarch64-linux native/emulated builds, so you only need to build a small amount of packages.
  - For aarch64-linux, native/emulated builds have a higher [support Tier in Nixpkgs](https://github.com/NixOS/rfcs/blob/master/rfcs/0046-platform-support-tiers.md) than cross builds.
  - Even if you don't have an AArch64 builder, the build time for emulated builds is still acceptable given the small amount of packages you need to build.
* For Zynq 7000, Nixpkgs doesn't provide a binary cache for armv7l-linux.
  - For native/emulated builds, you'll need to bootstrap from stage 0. For emulated builds, this is *really* time consuming.
  - For armv7l-linux, cross builds and native/emulated have the same level of support Tier. But in my experience, native/emulated builds are more problematic due to the limited userbase.

In short, I recommend native/emulated builds for ZynqMP, and cross builds for Zynq 7000.

### Emulated builds
- For NixOS, add this to the *builder's* configuration.nix:
  ```nix
  boot.binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux" ];
  ```
- For other systemd-based Linux distros, you need to install `qemu-user-static` (something like that), edit `/etc/binfmt.d/arm.conf` as follows:
  ```
  :aarch64-linux:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\x00\xff\xfe\xff\xff\xff:/usr/bin/qemu-aarch64-static:PF
  :armv7l-linux:M::\x7fELF\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x28\x00:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\x00\xff\xfe\xff\xff\xff:/usr/bin/qemu-armhf-static:PF
  ```
  Restart `systemd-binfmt.service`. Add `extra-platforms = aarch64-linux armv7l-linux` to your `/etc/nix/nix.conf`. Restart `nix-daemon.service`.

### Cross builds
Set `nixpkgs.buildPlatform` in the *target's* configuration to your *builder's* platform, for example:
```nix
nixpkgs.buildPlatform = "x86_64-linux";
```

### Native builds
Many AArch64 CPUs also supports AArch32, which provides backward compatibility with ARMv7. Such "aarch64-linux" systems can be used to build armv7l-linux natively.
  - Check whether your `lscpu` says `CPU op-mode(s): 32-bit, 64-bit`.
  - Add `extra-platforms = armv7l-linux` to your `/etc/nix/nix.conf`. Restart `nix-daemon.service`.

## Notes on Linux kernel

### Adding out-of-tree modules

```nix
boot.extraModulePackages = [ config.boot.kernelPackages.digilent-hdmi ];
```

List of out-of-tree Linux modules provided by Nixpkgs:

```shell
$ nix repl --file '<nixpkgs>'
nix-repl> linuxPackages.<TAB>
```

List of out-of-tree Linux modules provided by this repo is under [pkgs/](./pkgs/).

### Adding your own module

<details>
<summary>
Example Makefile:
</summary>

```makefile
# module-name/Makefile

ifeq ($(KERNELRELEASE),)

KDIR ?= /lib/modules/$(shell uname -r)/build

modules modules_install clean help:
	$(MAKE) -C $(KDIR) M=$(shell pwd) $@

else

obj-m += module-name.o

module-name-y := source_1.o
module-name-y += source_2.o

endif
```
</details>

<details>
<summary>
Example Nix package:
</summary>

```nix
# module-name/derivation.nix

{ lib, stdenv, kernel, kmod }:

stdenv.mkDerivation {
  name = "module-name";

  src = ./.;

  hardeningDisable = [ "pic" ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ kmod ];

  makeFlags = kernel.makeFlags ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];
  installTargets = [ "modules_install" ];

  enableParallelBuilding = true;
}
```
</details>

Add the package to your system's config:

```nix
boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ./module-name/derivation.nix { })
];
```

### Patching the kernel

```nix
boot.kernelPatches = [
  { name = "my-patch"; patch = ./my-patch.patch; }
];
```

### Modifying kernel config

```nix
boot.kernelPatches = [
  {
    name = "devmem";
    patch = null;
    extraStructuredConfig.STRICT_DEVMEM = lib.kernel.no;
    extraStructuredConfig.IO_STRICT_DEVMEM = lib.kernel.no;
  }
];
```

`lib.kernel.yes`, `lib.kernel.no`, `lib.kernel.module`. Use `lib.mkForce lib.kernel.no` if it conflicts with `nixpkgs/pkgs/os-specific/linux/kernel/common-config.nix`.

## Known issues

### Applications that requires OpenGL not launching

The Mali GPU built in ZynqMP isn't supported by Mesa yet. You have to use the closed source Mali OpenGL ES drivers:

```nix
hardware.graphics.extraPackages = [ pkgs.libmali-xlnx.x11 ]; # Possible choices: wayland, x11, fbdev, headless
boot.extraModulePackages = [ config.boot.kernelPackages.mali-module-xlnx ];
boot.blacklistedKernelModules = [ "lima" ];
boot.kernelModules = [ "mali" ];
```

### Xorg not launching

For some reason the Xorg modesetting driver doesn't work on ZynqMP DisplayPort subsystem. You have to use either armsoc or fbdev:

```nix
services.xserver.videoDrivers = lib.mkForce [ "armsoc" "fbdev" ];
```

<details>
<summary>
I haven't successfully launched a normal display manager on ZynqMP yet. If you also have issues with display managers, this is a working configuration:
</summary>

```nix
services.xserver.enable = true;
services.xserver.videoDrivers = lib.mkForce [ "armsoc" ];
services.xserver.displayManager.sx.enable = true;
services.xserver.windowManager.i3.enable = true;
systemd.services.i3 = {
  wantedBy = [ "graphical.target" ];
  script = ''
    . /etc/profile
    chvt 7
    exec sx i3 -c /etc/i3/config
  '';
  unitConfig.StartLimitIntervalSec = 0;
  serviceConfig = {
    User = "root";
    Group = "root";
    PAMName = "login";
    WorkingDirectory = "~";
    Restart = "always";
    TTYPath = "/dev/tty7";
    TTYReset = "yes";
    TTYVHangup = "yes";
    TTYVTDisallocate = "yes";
    StandardInput = "tty-force";
    StandardOutput = "journal";
    StandardError = "journal";
  };
};
```
</details>

## Contributing

Contributions are welcome! Just keep your pull requests focused on one feature at a time instead of contributing lots of changes at once. This makes reviews much easier. Thanks!

## Disclaimer

Zynq, ZynqMP, Zynq UltraScale+ MPSoC, Vivado, Vitis, PetaLinux are trademarks of Advanced Micro Devices, Inc. This project is not endorsed by nor affiliated with Advanced Micro Devices, Inc.

MIT license only applies to the files in this repository, not to the packages built with it. Licenses for patches in this repository are otherwise specified.
