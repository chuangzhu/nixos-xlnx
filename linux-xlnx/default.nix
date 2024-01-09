{ lib
, buildLinux
, fetchFromGitHub
, defconfig ? "xilinx_defconfig"
, kernelPatches ? [ ]
, ...
} @ args:

buildLinux (args // {
  version = "5.15.36-xilinx-v2022.2";
  modDirVersion = if defconfig == "xilinx_zynq_defconfig" then "5.15.0-xilinx" else "5.15.0";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "linux-xlnx";
    rev = "xilinx-v2022.2";
    hash = "sha256-8iPAKyK+jPkjl1TWn+IbiHN9iRyuWFivp/MeCEsNVlM=";
  };

  structuredExtraConfig = with lib.kernel; {
    DEBUG_INFO_BTF = lib.mkForce no;
  };

  kernelPatches = [
    # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
    { name = "fix-tps544-nsdeps"; patch = ./fix-tps544-nsdeps.patch; }
    # error: implicit declaration of function 'FIELD_PREP'
    { name = "xilinx-hdcp1x-cipher"; patch = ./xilinx-hdcp1x-cipher.patch; }
  ] ++ kernelPatches;

  extraMeta.platforms = [ "aarch64-linux" "armv7l-linux" ];
} // (args.argsOverride or { }))
