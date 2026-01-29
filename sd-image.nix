{
  config,
  pkgs,
  modulesPath,
  options,
  lib,
  ...
}:

{
  imports = [
    "${modulesPath}/profiles/base.nix"
    "${modulesPath}/installer/sd-card/sd-image.nix"
    ./nixos.nix
  ];
  disabledModules = [ "${modulesPath}/profiles/all-hardware.nix" ];

  config = {
    sdImage = {
      # Depending on the FSBL setup, BOOT.BIN can be quite large
      firmwareSize = 100;
      populateFirmwareCommands = ''
        cp ${config.hardware.zynq.boot-bin} firmware/BOOT.BIN
      '';
      populateRootCommands = ''
        mkdir -p ./files/boot
        ${config.boot.loader.generic-extlinux-compatible.populateCmd} -c ${config.system.build.toplevel} -d ./files/boot
      '';
    };

    # Contents of profiles/all-hardware.nix is transferred to an option in nixos-25.05
    # Had to do this because I want to make it backwards compatible
    hardware = lib.optionalAttrs (options.hardware ? enableAllHardware) {
      enableAllHardware = lib.mkForce false;
    };

    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "xlnx-firmware-update";
        text = ''
          systemctl start boot-firmware.mount
          cp ${config.hardware.zynq.boot-bin} /boot/firmware/BOOT.BIN
          sync /boot/firmware/BOOT.BIN
        '';
      })
    ];
  };
}
