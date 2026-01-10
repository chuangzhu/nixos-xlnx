{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ./boot-bin.nix ];

  options.hardware.zynq = {
    xlnxVersion = lib.mkOption {
      type = lib.types.enum [
        "2024.1"
        "2025.1"
      ];
      description = lib.mdDoc ''
        Xilinx Vivado Design Suite version of your hardware design.
      '';
    };
  };

  config = {
    boot.loader = {
      grub.enable = lib.mkDefault false;
      generic-extlinux-compatible.enable = lib.mkDefault true;
    };

    nixpkgs.overlays = [ (import ./overlay.nix { inherit (config.hardware.zynq) xlnxVersion; }) ];

    boot.kernelPackages = lib.mkDefault pkgs."linuxPackages_${config.hardware.zynq.platform}";

    boot.kernelParams = lib.mkDefault [
      "earlycon"
      "console=ttyPS0,115200n8"
    ];

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

    # Some modules specified in <nixpkgs/nixos/modules/system/boot/kernel.nix> aren't available...
    boot.initrd.includeDefaultModules = false;
    boot.initrd.availableKernelModules = [
      "ahci"
      "sata_inic162x"
      "sata_sil24"
      # NVMe
      "nvme"
      # Standard SCSI stuff.
      "sr_mod"
      # Support USB keyboards, in case the boot fails and we only have
      # a USB keyboard, or for LUKS passphrase prompt.
      "uhci_hcd"
      "ehci_hcd"
      "ehci_pci"
      "ohci_hcd"
      "ohci_pci"
      "usbhid"
      "hid_generic"
      "hid_lenovo"
      "hid_apple"
      "hid_roccat"
      "hid_logitech_hidpp"
      "hid_logitech_dj"
      "hid_microsoft"
      "hid_cherry"
    ]
    ++ lib.optionals (config.hardware.zynq.platform != "zynq") [
      "xhci_hcd"
      "xhci_pci"
      # Broadcom
      # "vc4"
    ];
  };
}
