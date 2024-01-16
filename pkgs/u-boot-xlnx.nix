{ lib
, fetchFromGitHub
, buildUBoot
, stdenv
, platform ? "zynqmp"
}:

buildUBoot {
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "u-boot-xlnx";
    rev = "xilinx-v2022.2";
    hash = "sha256-k8Uu9/X95L7r6OfrK7mo4ogTa872yeK7a+by/ryZc4I=";
  };

  defconfig = "xilinx_${platform}_virt_defconfig";
  extraMeta.platforms = if platform == "zynq" then [ "armv7l-linux" ] else [ "aarch64-linux" ];

  filesToInstall = [ "u-boot.elf" ];
}
