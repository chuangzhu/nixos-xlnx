{ lib
, buildArmTrustedFirmware
}:

buildArmTrustedFirmware rec {
  extraMakeFlags = [ "bl31" ];
  platform = "zynqmp";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf"];
  platformCanUseHDCPBlob = true;
}
