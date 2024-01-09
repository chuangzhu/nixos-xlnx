{ lib
, fetchFromGitHub
, buildArmTrustedFirmware
, unfreeIncludeHDCPBlob ? false
}:

buildArmTrustedFirmware rec {
  version = "2.6.0";
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "arm-trusted-firmware";
    rev = "xilinx-v2022.2";
    hash = "sha256-yT9WofFgZLbGYXr6bxFuXL1ouC8UI+rICXBCmoM8ZLs=";
  };
  extraMakeFlags = [ "bl31" ];
  platform = "zynqmp";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
  platformCanUseHDCPBlob = unfreeIncludeHDCPBlob;
}
