{ lib
, fetchFromGitHub
, buildArmTrustedFirmware
, unfreeIncludeHDCPBlob ? false
}:

buildArmTrustedFirmware rec {
  version = "2.8.0";
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "arm-trusted-firmware";
    rev = "xilinx-v2023.2";
    hash = "sha256-RvdBsskiSgquwnDf0g0dU8P6v4QxK4OqhtkF5K7lfyI=";
  };
  extraMakeFlags = [ "bl31" ];
  platform = "zynqmp";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
  platformCanUseHDCPBlob = unfreeIncludeHDCPBlob;
}
