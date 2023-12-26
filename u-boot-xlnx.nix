{ lib
, fetchFromGitHub
, buildArmTrustedFirmware
, buildUBoot
, writeText
, xilinx-bootgen
, stdenv
}:

buildUBoot {
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "u-boot-xlnx";
    rev = "xilinx-v2022.2";
    hash = "sha256-k8Uu9/X95L7r6OfrK7mo4ogTa872yeK7a+by/ryZc4I=";
  };

  defconfig = "xilinx_zynqmp_virt_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];

  filesToInstall = [ "u-boot.elf" ];
}
