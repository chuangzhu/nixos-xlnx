{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, runCommand
, armTrustedFirmwareZynqMP
, ubootZynqMP
, bitstream ? null # system.bit
, fsbl ? null # fsbl_a53.elf
, pmufw ? null # pmufw.elf
, dtb ? null # system.dtb
}:

runCommand "BOOT.BIN" { } ''
  mkdir $out/
  ${xilinx-bootgen.overrideAttrs rec {
    version = "xilinx_v2022.2";
    src = fetchFromGitHub {
      owner = "Xilinx";
      repo = "bootgen";
      rev = version;
      hash = "sha256-bnvF0rRWvMuqeLjXfEQ9uaS1x/3iE/jLM3yoiBN0xbU=";
    };
  }}/bin/bootgen -image ${writeText "bootgen.bif" ''
    the_ROM_image: {
      [bootloader, destination_cpu=a53-0] ${fsbl}
      [pmufw_image] ${pmufw}
      [destination_device=pl] ${bitstream}
      [destination_cpu=a53-0, exception_level=el-3, trustzone] ${armTrustedFirmwareZynqMP}/bl31.elf
      [destination_cpu=a53-0, load=0x00100000] ${dtb}
      [destination_cpu=a53-0, exception_level=el-2] ${ubootZynqMP}/u-boot.elf
    }
  ''} -arch zynqmp -w -o $out/BOOT.BIN
''
