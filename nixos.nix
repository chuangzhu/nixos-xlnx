{ config, lib, pkgs, ... }:

{
  boot.loader = {
    grub.enable = lib.mkDefault false;
    generic-extlinux-compatible.enable = lib.mkDefault true;
  };

  nixpkgs.overlays = [ (import ./overlay.nix) ];

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_xlnx;

  boot.kernelParams = lib.mkDefault [ "earlycon" "console=ttyPS0,115200n8" ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
