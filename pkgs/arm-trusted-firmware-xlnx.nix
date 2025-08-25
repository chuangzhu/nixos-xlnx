{ lib
, stdenv
, fetchFromGitHub
, buildArmTrustedFirmware
, openssl
, unfreeIncludeHDCPBlob ? false
, xlnxVersion ? "2025.1"
}:

let
  atfVersion = {
    "2024.1" = "2.10";
    "2025.1" = "2.12";
  }.${xlnxVersion};
in

(buildArmTrustedFirmware rec {
  version = atfVersion;
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "arm-trusted-firmware";
    rev = "xlnx_rebase_v${atfVersion}_${xlnxVersion}";
    hash = {
      "2024.1" = "sha256-XEFHS2hZWdJEB7b0Zdci/PtNc7csn+zQWljiG9Tx0mM=";
      "2025.1" = "sha256-HIqfsenTlAU+e3SmKfHZNLrPDcUZIWF222Ur0BYS7zc=";
    }.${xlnxVersion};
  };
  extraMakeFlags = [ "bl31" ];
  platform = "zynqmp";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/bl31/bl31.elf" ];
  platformCanUseHDCPBlob = unfreeIncludeHDCPBlob;
}).overrideAttrs {
  makeFlags = [
    "bl31"
    "PLAT=zynqmp"

    "HOSTCC=$(CC_FOR_BUILD)"
    # "M0_CROSS_COMPILE=${pkgsCross.arm-embedded.stdenv.cc.targetPrefix}"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
  ] ++ lib.optionals (lib.versionOlder atfVersion "2.11") [
    # https://github.com/NixOS/nixpkgs/blob/staging-24.11/pkgs/misc/arm-trusted-firmware/default.nix
    # binutils 2.39 regression
    # `warning: /build/source/build/rk3399/release/bl31/bl31.elf has a LOAD segment with RWX permissions`
    # See also: https://developer.trustedfirmware.org/T996
    "LDFLAGS=-no-warn-rwx-segments"
  ] ++ lib.optionals (lib.versionAtLeast atfVersion "2.11") [
    # https://github.com/NixOS/nixpkgs/blob/nixos-25.05/pkgs/misc/arm-trusted-firmware/default.nix
    # Make the new toolchain guessing (from 2.11+) happy
    "CC=${stdenv.cc.targetPrefix}cc"
    "LD=${stdenv.cc.targetPrefix}cc"
    "AS=${stdenv.cc.targetPrefix}cc"
    "OC=${stdenv.cc.targetPrefix}objcopy"
    "OD=${stdenv.cc.targetPrefix}objdump"
    # Passing OpenSSL path according to docs/design/trusted-board-boot-build.rst
    "OPENSSL_DIR=${openssl}"
  ];
}
