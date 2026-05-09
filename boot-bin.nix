{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hardware.zynq;

  # embeddedsw/cmake/toolchainfiles/cortexa9_toolchain.cmake
  fsblCross =
    if cfg.platform == "zynqmp" then
      pkgs.pkgsCross.aarch64-embedded
    else
      import pkgs.path {
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
        overlays = [ (import ./overlay.nix { inherit (config.hardware.zynq) xlnxVersion; }) ];
      };

  bifEntryType = lib.types.submodule {
    options = {
      attributes = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = [
          "bootloader"
          "destination_cpu=a53-0"
        ];
        description = ''
          Bracketed attributes for this BIF entry, rendered as
          `[attr1, attr2, ...]` before the value. `null` (the default)
          emits no brackets.
        '';
      };
      value = lib.mkOption {
        type = lib.types.either lib.types.str lib.types.path;
        example = lib.literalExpression ''"''${pkgs.armTrustedFirmwareZynqMP}/bl31.elf"'';
        description = ''
          Path or string emitted after the attribute list. Usually a path
          to a binary (FSBL, PMUFW, bitstream, ELF, dtb), or a parameter string
          for attributes such as `[auth_params] ppk_select=0;spk_id=0x0`.
        '';
      };
    };
  };

  renderBifEntry =
    entry:
    let
      attrs =
        if entry.attributes == null || entry.attributes == [ ] then
          ""
        else
          "[${lib.concatStringsSep ", " entry.attributes}] ";
    in
    "${attrs}${toString entry.value}";
in

{
  options.hardware.zynq = {
    platform = lib.mkOption {
      type = lib.types.enum [
        "zynq"
        "zynqmp"
      ];
      description = ''
        Whether you use Zynq 7000 or Zynq UltraScale+ MPSoC.
      '';
    };

    sdtDir = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/sdt";
      description = ''
        Directory to system-device-tree sources.
        Since Vivado v2024.1, it's possible to build FSBL and PMUFW in Nix.

        SDT files can be generated from XSA using {command}`./gendt.tcl`.
      '';
    };
    dtDir = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/dt";
      description = ''
        Directory to device-tree sources.

        DT files can be generated from XSA using {command}`./gendt.tcl`.
      '';
    };
    dtb = lib.mkOption {
      type = lib.types.path;
      defaultText = lib.literalMD "built from {option}`hardware.zynq.dtDir`";
      default = pkgs.runCommandCC "system.dtb" { nativeBuildInputs = [ pkgs.dtc ]; } ''
        ${pkgs.stdenv.cc.targetPrefix}cpp -nostdinc -undef -x assembler-with-cpp ${cfg.dtDir}/system-top.dts -isystem ${cfg.dtDir}/include -o combined.dts
        dtc -@ -I dts -O dtb combined.dts -o $out
      '';
      example = lib.literalExpression "./firmware/system.dtb";
      description = ''
        Nixos-xlnx uses this for {option}`hardware.deviceTree.dtbSource`.
        Note you can still use {option}`hardware.deviceTree.overlays` to
        update your device tree configurations.
      '';
    };

    bitstream = lib.mkOption {
      type = lib.types.path;
      example = lib.literalExpression "./gendt/sdt/vivado_exported.bit";
      description = ''
        Path to bitstream extracted from XSA.
        If you are using {command}`scripts/gendt.tcl`, it is extracted to the `sdt` directory.
      '';
    };
    fsbl = lib.mkOption {
      type = lib.types.path;
      defaultText = lib.literalMD "generated from {option}`hardware.zynq.sdtDir`";
      default =
        fsblCross."${cfg.platform}-fsbl".override { inherit (cfg) sdtDir; } + "/${cfg.platform}_fsbl.elf";
      example = lib.literalExpression "./firmware/fsbl_a53.elf";
      description = ''
        Path to First Stage Boot Loader.
      '';
    };
    pmufw = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      defaultText = lib.literalMD "generated from {option}`hardware.zynq.sdtDir`";
      default =
        if cfg.platform == "zynqmp" then
          pkgs.pkgsCross.microblaze-embedded.zynqmp-pmufw.override { inherit (cfg) sdtDir; }
          + "/zynqmp_pmufw.elf"
        else
          null;
      example = lib.literalExpression "./firmware/pmufw.elf";
      description = ''
        Path to Zynq MPSoC Platform Management Unit Firmware.
      '';
    };

    bif = {
      imageName = lib.mkOption {
        type = lib.types.str;
        default = "the_ROM_image";
        description = ''
          Image name for the BIF (the identifier before the opening brace).
          Rarely needs to be changed.
        '';
      };

      entries = lib.mkOption {
        type = lib.types.listOf bifEntryType;
        default =
          let
            dtb = "${config.hardware.deviceTree.package}/system.dtb";
          in
          {
            zynqmp = [
              {
                attributes = [
                  "bootloader"
                  "destination_cpu=a53-0"
                ];
                value = cfg.fsbl;
              }
              {
                attributes = [ "pmufw_image" ];
                value = cfg.pmufw;
              }
              {
                attributes = [ "destination_device=pl" ];
                value = cfg.bitstream;
              }
              {
                attributes = [
                  "destination_cpu=a53-0"
                  "exception_level=el-3"
                  "trustzone"
                ];
                value = "${pkgs.armTrustedFirmwareZynqMP}/bl31.elf";
              }
              {
                attributes = [
                  "destination_cpu=a53-0"
                  "load=0x00100000"
                ];
                value = dtb;
              }
              {
                attributes = [
                  "destination_cpu=a53-0"
                  "exception_level=el-2"
                ];
                value = "${pkgs.ubootZynqMP}/u-boot.elf";
              }
            ];
            zynq = [
              {
                attributes = [ "bootloader" ];
                value = cfg.fsbl;
              }
              { value = cfg.bitstream; }
              { value = "${pkgs.ubootZynq}/u-boot.elf"; }
              {
                attributes = [ "load=0x00100000" ];
                value = dtb;
              }
            ];
          }
          .${cfg.platform};
        defaultText = lib.literalMD ''
          Platform-specific list of FSBL, PMUFW, bitstream, ATF, U-Boot, and dtb entries.
        '';
        example = lib.literalExpression ''
          options.hardware.zynq.bif.entries.default ++ [
            {
              attributes = [
                "destination_cpu=a53-0"
                "exception_level=el-1"
                "trustzone"
              ];
              value = "''${pkgs.opteeOsZynqMP}/tee.elf";
            }
          ]
        '';
        description = ''
          Structured list of BIF entries. Each entry renders as
          `[attr1, attr2] value`.
        '';
      };

      text = lib.mkOption {
        type = lib.types.str;
        defaultText = lib.literalMD ''
          Built from {option}`hardware.zynq.bif.imageName` and
          {option}`hardware.zynq.bif.entries`.
        '';
        description = ''
          The full BIF text passed to bootgen. Override directly for full
          control (e.g. multi-image partitions).
        '';
      };

      file = lib.mkOption {
        type = lib.types.path;
        defaultText = lib.literalMD ''
          {option}`hardware.zynq.bif.text` written to a file in the Nix store.
        '';
        description = ''
          The BIF written out as a file. Useful for invoking `bootgen`
          manually outside the Nix store, e.g. when secret AES/RSA keys
          should not end up world-readable in `/nix/store`:

          ```
          nix build .#nixosConfigurations.<hostname>.config.hardware.zynq.bif.file
          bootgen -image ./result -arch zynqmp -p xczu9eg -encrypt efuse -w -o BOOT.BIN
          ```
        '';
      };
    };

    boot-bin = lib.mkOption {
      type = lib.types.path;
      defaultText = lib.literalMD "built by bootgen from {option}`hardware.zynq.bif.file`";
      description = ''
        You can build BOOT.BIN without building the whole system using
        {command}`nix build .#nixosConfigurations.<hostname>.config.hardware.zynq.boot-bin`
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

    hardware.zynq.bif.text = lib.mkDefault ''
      ${cfg.bif.imageName}: {
      ${lib.concatMapStringsSep "\n" (l: "  ${l}") (map renderBifEntry cfg.bif.entries)}
      }
    '';

    hardware.zynq.bif.file = lib.mkDefault (pkgs.writeText "bootgen.bif" cfg.bif.text);

    hardware.zynq.boot-bin = lib.mkDefault (
      pkgs.runCommand "BOOT.BIN" { nativeBuildInputs = [ pkgs.xilinx-bootgen_nixosxlnx ]; } ''
        bootgen -image ${cfg.bif.file} -arch ${cfg.platform} -w -o $out
      ''
    );
  };
}
