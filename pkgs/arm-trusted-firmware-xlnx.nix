{ lib
, fetchFromGitHub
, buildArmTrustedFirmware
, unfreeIncludeHDCPBlob ? false
}:

buildArmTrustedFirmware rec {
  version = "2.10";
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "arm-trusted-firmware";
    rev = "xlnx_rebase_v2.10_2024.1";
    hash = "sha256-XEFHS2hZWdJEB7b0Zdci/PtNc7csn+zQWljiG9Tx0mM=";
  };
  extraMakeFlags = [ "bl31" ];
  platform = "zynqmp";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
  platformCanUseHDCPBlob = unfreeIncludeHDCPBlob;
}
