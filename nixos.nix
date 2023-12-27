{ config, lib, pkgs, ... }:

{
  options.hardware.zynq = {
    dtb = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./firmware/system.dtb";
      description = lib.mdDoc ''
        Generation for device tree from XSA file in Nix is not implemented yet.
        You need to provide the path to system.dtb generated by Vitis.
        Can be semi-automated using {command}`./vitisgenfw.tcl <vivado_exported.xsa>`

        Nixos-xlnx uses this for {option}`hardware.deviceTree.dtbSource`.
        Note you can still use {option}`hardware.deviceTree.overlays` to
        update your device tree configurations.
      '';
    };
  };

  config = {
    boot.loader = {
      grub.enable = lib.mkDefault false;
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };

    nixpkgs.overlays = [ (import ./overlay.nix) ];

    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_xlnx;

    boot.kernelParams = lib.mkDefault [ "earlycon" "console=ttyPS0,115200n8" ];

    hardware.deviceTree = {
      enable = true;
      dtbSource = pkgs.runCommand "dtb-source" { } ''
        mkdir $out/
        cp ${config.hardware.zynq.dtb} $out/system.dtb
      '';
      # If not specified, U-Boot uses the non-existent ${dtbSource}/xilinx/zynqmp.dtb
      name = "system.dtb";
    };

    nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  };
}