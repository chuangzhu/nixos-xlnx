{ lib
, buildLinux
, fetchFromGitHub
, writeText
, kernelPatches ? [ ]
, ...
} @ args:

buildLinux (args // {
  version = "5.15.36-xilinx-v2022.2";
  modDirVersion = "5.15.0";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "linux-xlnx";
    rev = "xilinx-v2022.2";
    hash = "sha256-8iPAKyK+jPkjl1TWn+IbiHN9iRyuWFivp/MeCEsNVlM=";
  };

  defconfig = "xilinx_defconfig";
  structuredExtraConfig = with lib.kernel; {
    DEBUG_INFO_BTF = lib.mkForce no;
  };

  # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
  kernelPatches = lib.singleton {
    name = "fix-tps544-nsdeps";
    patch = writeText "fix-tps544-nsdeps.patch" ''
      diff --git a/drivers/hwmon/pmbus/tps544.c b/drivers/hwmon/pmbus/tps544.c
      index 3cf31ff47906..6bfc2164aa7b 100644
      --- a/drivers/hwmon/pmbus/tps544.c
      +++ b/drivers/hwmon/pmbus/tps544.c
      @@ -360,3 +360,4 @@ module_i2c_driver(tps544_driver);
       MODULE_AUTHOR("Harini Katakam");
       MODULE_DESCRIPTION("PMBus regulator driver for TPS544");
       MODULE_LICENSE("GPL v2");
      +MODULE_IMPORT_NS(PMBUS);
    '';
  } ++ kernelPatches;

  extraMeta.platforms = [ "aarch64-linux" "armv7l-linux" ];
} // (args.argsOverride or { }))
