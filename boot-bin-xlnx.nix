{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, runCommand
, armTrustedFirmwareXlnx
, ubootXlnx
, bitstream ? null # system.bit
, fsbl ? null # zynqmp_fsbl.elf
, pmufw ? null # pmufw.elf
, dtb ? null # system.dtb
}:

runCommand "BOOT.BIN" { } ''
  mkdir $out/
  ${xilinx-bootgen.overrideAttrs (_: {
    src = fetchFromGitHub {
      owner = "Xilinx";
      repo = "bootgen";
      rev = "xilinx_v2022.2";
      hash = "sha256-bnvF0rRWvMuqeLjXfEQ9uaS1x/3iE/jLM3yoiBN0xbU=";
    };
  })}/bin/bootgen -image ${writeText "bootgen.bif" ''
    the_ROM_image: {
      [bootloader, destination_cpu=a53-0] ${fsbl}
      [pmufw_image] ${pmufw}
      [destination_device=pl] ${bitstream}
      [destination_cpu=a53-0, exception_level=el-3, trustzone] ${armTrustedFirmwareXlnx}/bl31.elf
      [destination_cpu=a53-0, load=0x00100000] ${dtb}
      [destination_cpu=a53-0, exception_level=el-2] ${ubootXlnx}/u-boot.elf
    }
  ''} -arch zynqmp -w -o $out/BOOT.BIN
''
