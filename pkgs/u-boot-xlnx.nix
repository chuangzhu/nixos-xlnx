{ lib
, fetchFromGitHub
, buildUBoot
, stdenv
, platform ? "zynqmp"
}:

buildUBoot {
  version = "2024.1";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "u-boot-xlnx";
    rev = "xilinx-v2024.1";
    hash = "sha256-G6GOcazwY4A/muG2hh4pj8i9jm536kYhirrOzcn77WE=";
  };

  defconfig = "xilinx_${platform}_virt_defconfig";
  extraMeta.platforms = if platform == "zynq" then [ "armv7l-linux" ] else [ "aarch64-linux" ];

  filesToInstall = [ "u-boot.elf" ];
}
