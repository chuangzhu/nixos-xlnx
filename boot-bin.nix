{ config, pkgs, lib, ... }:

let
  cfg = config.hardware.zynq;

  # embeddedsw/cmake/toolchainfiles/cortexa9_toolchain.cmake
  fsblCross = if cfg.platform == "zynqmp" then pkgs.pkgsCross.aarch64-embedded else import pkgs.path {
    localSystem.system = pkgs.stdenv.buildPlatform.system;
    crossSystem = {
      config = "arm-none-eabihf";
      libc = "newlib";
      gcc = {
        cpu = "cortex-a9";
        fpu = "vfpv3";
        float-abi = "hard";
      };
    };
    overlays = [ (import ./overlay.nix) ];
  };
in

{
  options.hardware.zynq = {
    platform = lib.mkOption {
      type = lib.types.enum [ "zynq" "zynqmp" ];
      description = lib.mdDoc ''
        Whether you use Zynq 7000 or Zynq UltraScale+ MPSoC.
      '';
    };

    sdtDir = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/sdt";
      description = lib.mdDoc ''
        Directory to system-device-tree sources.
        Since Vivado v2024.1, it's possible to build FSBL and PMUFW in Nix.

        SDT files can be generated from XSA using {command}`./gendt.tcl`.
      '';
    };
    dtDir = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/dt";
      description = lib.mdDoc ''
        Directory to device-tree sources.

        DT files can be generated from XSA using {command}`./gendt.tcl`.
      '';
    };
    dtb = lib.mkOption {
      type = lib.types.path;
      defaultText = lib.literalMD "built from {option}`hardware.zynq.dtDir`";
      default = pkgs.runCommandCC "system.dtb" { nativeBuildInputs = [ pkgs.dtc ]; } ''
        ${pkgs.stdenv.cc.targetPrefix}cpp -nostdinc -undef -x assembler-with-cpp ${cfg.dtDir}/system-top.dts -o combined.dts
        dtc -@ -I dts -O dtb combined.dts -o $out
      '';
      example = lib.literalExpression "./firmware/system.dtb";
      description = lib.mdDoc ''
        Nixos-xlnx uses this for {option}`hardware.deviceTree.dtbSource`.
        Note you can still use {option}`hardware.deviceTree.overlays` to
        update your device tree configurations.
      '';
    };

    bitstream = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/sdt/vivado_exported.bit";
      description = lib.mdDoc ''
        Path to bitstream extracted from XSA.
        If you are using {command}`scripts/gendt.tcl`, it is extracted to the `sdt` directory.
      '';
    };
    fsbl = lib.mkOption {
      type = lib.types.path;
      defaultText = lib.literalMD "generated from {option}`hardware.zynq.sdtDir`";
      default = fsblCross."${cfg.platform}-fsbl".override { inherit (cfg) sdtDir; } + "/${cfg.platform}_fsbl.elf";
      example = lib.literalExpression "./firmware/fsbl_a53.elf";
      description = lib.mdDoc ''
        Path to First Stage Boot Loader.
      '';
    };
    pmufw = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      defaultText = lib.literalMD "generated from {option}`hardware.zynq.sdtDir`";
      default = if cfg.platform == "zynqmp"
        then pkgs.pkgsCross.microblaze-embedded.zynqmp-pmufw.override { inherit (cfg) sdtDir; } + "/zynqmp_pmufw.elf"
        else null;
      example = lib.literalExpression "./firmware/pmufw.elf";
      description = lib.mdDoc ''
        Path to Zynq MPSoC Platform Management Unit Firmware.
      '';
    };

    boot-bin = lib.mkOption {
      type = lib.types.path;
      defaultText = "generated from fsbl, pmufw, bitstream, and dtb";
      default = let
        dtb = "${config.hardware.deviceTree.package}/system.dtb";
        bif = {
          zynqmp = ''
            the_ROM_image: {
              [bootloader, destination_cpu=a53-0] ${cfg.fsbl}
              [pmufw_image] ${cfg.pmufw}
              [destination_device=pl] ${cfg.bitstream}
              [destination_cpu=a53-0, exception_level=el-3, trustzone] ${pkgs.armTrustedFirmwareZynqMP}/bl31.elf
              [destination_cpu=a53-0, load=0x00100000] ${dtb}
              [destination_cpu=a53-0, exception_level=el-2] ${pkgs.ubootZynqMP}/u-boot.elf
            }
          '';
          zynq = ''
            the_ROM_image: {
              [bootloader] ${cfg.fsbl}
              ${cfg.bitstream}
              ${pkgs.ubootZynq}/u-boot.elf
              [load=0x00100000] ${dtb}
            }
          '';
        }.${cfg.platform};
      in pkgs.runCommand "BOOT.BIN" { nativeBuildInputs = [ pkgs.xilinx-bootgen_2024_1 ]; } ''
        bootgen -image ${pkgs.writeText "bootgen.bif" bif} -arch ${cfg.platform} -w -o $out
      '';
      description = lib.mdDoc ''
        You can build BOOT.BIN without building the whole system using
        {command}`nix build .#nixosConfigurations.<hostname>.cfg.boot-bin`
      '';
    };
  };

  config = {
    assertions = [
      {
        assertion = cfg.platform == "zynqmp" -> cfg.pmufw != null;
        message = "hardware.zynq.pmufw is not optional on ZynqMP.";
      }
    ];
  };
}
