# nixos-xlnx

NixOS and Nix packages for Xilinx Zynq 7000 SoCs and Zynq UltraScale+ MPSoCs. It's like PetaLinux, but instead of Yocto/OpenEmbedded/BitBake, it uses NixOS/Nixpkgs/Nix. Currently it targets Vivado 2024.1 and Nixpkgs unstable.

This project isn't considered stable yet. Options may change anytime without noticing. Pin your inputs!

## Limitations

Since Vivado v2024.1, FSBL and PMUFW can be built from source using the system-device-tree flow. However, system-device-tree and device-tree generation from XSA still requires Vivado HSI to work. You need to run [`gendt.tcl`](./gendt.tcl) in XSCT to do that.

## Build SD card images

After finishing your hardware design in Vivado, choose File > Export > Export Hardware... Save the XSA file. Run [`gendt.tcl`](./gendt.tcl) to generate the device-tree and system-device-tree.

```bash
git clone https://github.com/Xilinx/device-tree-xlnx ~/.cache/device-tree-xlnx -b xilinx_v2024.1 --depth 1
source /installation/path/to/Vivado/2024.1/settings64.sh
./gendt.tcl vivado_exported.xsa ./output/directory/ -platform zynqmp  # Or "zynq" for Zynq 7000
```

Assuming you have [Nix flakes](https://nixos.wiki/wiki/Flakes) enabled, configure NixOS as follows:

```nix
{
  inputs.nixos-xlnx.url = "github:chuangzhu/nixpkgs";

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
            pmufw = nixos-xlnx.legacyPackages.aarch64-linux.pkgsCross.pmu.zynqmp-pmufw.override { inherit (config.hardware.zynq) sdtDir; } + "/zynqmp_pmufw.elf";  # Remove for Zynq 7000
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

Vivado only knows your PL/PS configuration *inside the SoC*. Therefore, the generated device-tree may not suit your *board* configuration. If you used PetaLinux before, you know that frequently you need to override properties, add/delete nodes in DTSIs in a special directory. In NixOS, we use device-tree overlays for that. Note that overlay DTSs are slightly different with a regular DTS:

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
  - For armv7l-linux, cross builds and native/emulated have the same level of support Tier. But from my experience, native/emulated builds are more problematic due to limited userbase.

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
services.xserver.videoDrivers = lib.mkForce [ /*"armsoc"*/ "fbdev" ];
services.xserver.displayManager.sx.enable = true;
services.xserver.windowManager.i3.enable = true;
systemd.services.i3 = {
  wantedBy = [ "multi-user.target" ];
  script = ''
    . /etc/profile
    exec sx i3 -c /etc/i3/config
  '';
  # Sometimes systemd deactivate it instantly even with no error
  # Restart indefinitely
  unitConfig.StartLimitIntervalSec = 0;
  serviceConfig = {
    User = "root";
    Group = "root";
    PAMName = "login";
    WorkingDirectory = "~";
    Restart = "always";
    TTYPath = "/dev/tty1";
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

## Disclaimer

Zynq, ZynqMP, Zynq UltraScale+ MPSoC, Vivado, Vitis, PetaLinux are trademarks of Xilinx, Inc. This project is not endorsed by nor affiliated with Xilinx, Inc.

MIT license only applies to the files in this repository, not to the packages built with it. Licenses for patches in this repository are otherwise specified.
