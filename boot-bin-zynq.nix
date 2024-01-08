{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, runCommand
, ubootZynq
, bitstream ? null # system.bit
, fsbl ? null # fsbl.elf
, pmufw ? null
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
      [bootloader] ${fsbl}
      ${bitstream}
      ${ubootZynq}/u-boot.elf
      [load=0x00100000] ${dtb}
    }
  ''} -arch zynq -w -o $out/BOOT.BIN
''
