{ lib
, fetchFromGitHub
, buildUBoot
, stdenv
, platform ? "zynqmp"
}:

buildUBoot {
  version = "2023.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "u-boot-xlnx";
    rev = "xilinx-v2023.2";
    hash = "sha256-tSOw7+Pe3/JYIgrPYB6exPzfGrRTuolxXXTux80w/X8=";
  };

  defconfig = "xilinx_${platform}_virt_defconfig";
  extraMeta.platforms = if platform == "zynq" then [ "armv7l-linux" ] else [ "aarch64-linux" ];

  filesToInstall = [ "u-boot.elf" ];
}
