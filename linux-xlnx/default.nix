{ lib
, buildLinux
, fetchFromGitHub
, stdenv
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
  } // lib.optionalAttrs (defconfig == "xilinx_zynq_defconfig") {
    DRM_XLNX_BRIDGE = yes;  # DRM_XLNX uses xlnx_bridge_helper_init
    USB_XHCI_PLATFORM = no;  # USB_XHCI_PLATFORM uses dwc3_host_wakeup_capable
    USB_XHCI_HCD = no;
    USB_DWC3 = no;
    USB_CDNS_SUPPORT = no;
  } //  lib.optionalAttrs stdenv.is32bit {
    VIDEO_XILINX_HDMI21RXSS = no;  # FIXME: div64
  };

  kernelPatches = [
    # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
    { name = "fix-tps544-nsdeps"; patch = ./fix-tps544-nsdeps.patch; }
    # error: implicit declaration of function 'FIELD_PREP'
    { name = "xilinx-hdcp1x-cipher"; patch = ./xilinx-hdcp1x-cipher.patch; }
  ] ++ lib.optionals stdenv.is32bit [
    # ERROR: modpost: "__aeabi_ldivmod" [drivers/clk/clk-xlnx-clock-wizard.ko] undefined!
    { name = "fix-various-xilinx-modules-div64"; patch = ./fix-various-xilinx-modules-div64.patch; }
  ] ++ kernelPatches;

  extraMeta.platforms = [ "aarch64-linux" "armv7l-linux" ];
} // (args.argsOverride or { }))
