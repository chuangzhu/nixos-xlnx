{ config, pkgs, lib, ... }:

{
  options.hardware.zynq = {
    platform = lib.mkOption {
      type = lib.types.enum [ "zynq" "zynqmp" ];
      description = lib.mdDoc ''
        Whether you use Zynq 7000 or Zynq UltraScale+ MPSoC.
      '';
    };
    dtb = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./firmware/system.dtb";
      description = lib.mdDoc ''
        Generation for device tree from XSA file in Nix is not implemented yet.
        You need to provide the path to system.dtb generated by Vitis.
        Can be semi-automated using {command}`./vitisgenfw.tcl`

        Nixos-xlnx uses this for {option}`hardware.deviceTree.dtbSource`.
        Note you can still use {option}`hardware.deviceTree.overlays` to
        update your device tree configurations.
      '';
    };

    bitstream = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./firmware/system.bit";
      description = lib.mdDoc ''
        Generation for bitstream from XSA file in Nix is not implemented yet.
        You need to provide the path to system.bit generated by Vitis.
        Can be semi-automated using {command}`./vitisgenfw.tcl`
      '';
    };
    fsbl = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./firmware/fsbl_a53.elf";
      description = lib.mdDoc ''
        Generation for First Stage Boot Loader from XSA file in Nix is not implemented yet.
        You need to provide the path to fsbl_a53.elf generated by Vitis.
        Can be semi-automated using {command}`./vitisgenfw.tcl`
      '';
    };
    pmufw = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression "./firmware/pmufw.elf";
      description = lib.mdDoc ''
        Generation for Zynq MPSoC Platform Management Unit Firmware from XSA file in Nix is not implemented yet.
        You need to provide the path to pmufw.elf generated by Vitis.
        Can be semi-automated using {command}`./vitisgenfw.tcl`
      '';
    };

    boot-bin = lib.mkOption {
      type = lib.types.path;
      default = let
        dtb = "${config.hardware.deviceTree.package}/system.dtb";
        bif = {
          zynqmp = ''
            the_ROM_image: {
              [bootloader, destination_cpu=a53-0] ${config.hardware.zynq.fsbl}
              [pmufw_image] ${config.hardware.zynq.pmufw}
              [destination_device=pl] ${config.hardware.zynq.bitstream}
              [destination_cpu=a53-0, exception_level=el-3, trustzone] ${pkgs.armTrustedFirmwareZynqMP}/bl31.elf
              [destination_cpu=a53-0, load=0x00100000] ${dtb}
              [destination_cpu=a53-0, exception_level=el-2] ${pkgs.ubootZynqMP}/u-boot.elf
            }
          '';
          zynq = ''
            the_ROM_image: {
              [bootloader] ${config.hardware.zynq.fsbl}
              ${config.hardware.zynq.bitstream}
              ${pkgs.ubootZynq}/u-boot.elf
              [load=0x00100000] ${dtb}
            }
          '';
        }.${config.hardware.zynq.platform};
      in pkgs.runCommand "BOOT.BIN" { nativeBuildInputs = [ pkgs.xilinx-bootgen_2022_2 ]; } ''
        bootgen -image ${pkgs.writeText "bootgen.bif" bif} -arch ${config.hardware.zynq.platform} -w -o $out
      '';
      description = lib.mdDoc ''
        You can build BOOT.BIN without building the whole system using
        {command}`nix build .#nixosConfigurations.<hostname>.config.hardware.zynq.boot-bin`
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = config.hardware.zynq.platform == "zynqmp" -> config.hardware.zynq.pmufw != null;
        message = "hardware.zynq.pmufw is not optional on ZynqMP.";
      }
    ];
  };
}
