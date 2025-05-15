{ lib
, buildLinux
, fetchFromGitHub
, stdenv
, defconfig ? "xilinx_defconfig"
, kernelPatches ? [ ]
, version ? "6.6.10-xilinx-v2024.1"
, ...
} @ args:

buildLinux (args // {
  inherit version;
  modDirVersion = if defconfig == "xilinx_zynq_defconfig" then "6.6.10-xilinx" else "6.6.10";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "linux-xlnx";
    rev = "xlnx_rebase_v6.6_LTS_2024.1";
    hash = "sha256-tfpNLRtC9OQZfWaLkaGM42bqhLICDPeT5AoE271p3a0=";
  };

  structuredExtraConfig = with lib.kernel; {
    DEBUG_INFO_BTF = lib.mkForce no;
    CRYPTO_DEV_XILINX_ECDSA = no;  # Error: modpost: "ecdsasignature_decoder" undefined!
  } // lib.optionalAttrs (defconfig == "xilinx_zynq_defconfig") {
    DRM_XLNX_BRIDGE = yes;  # DRM_XLNX uses xlnx_bridge_helper_init
    USB_XHCI_PLATFORM = no;  # USB_XHCI_PLATFORM uses dwc3_host_wakeup_capable
    USB_XHCI_HCD = no;
    USB_DWC3 = no;
    USB_CDNS_SUPPORT = no;
  } // lib.optionalAttrs stdenv.is32bit {
    # Disable HDCP on Zynq7 to avoid hard-to-fix compilation errors
    # These are only relevant to XC7Z045 and XC7Z100 anyway
    # For other Zynq7 devices, use https://digilent.com/reference/programmable-logic/zybo-z7/demos/hdmi instead
    # If you are using XC7Z045 or XC7Z100 and do want to use these features, please open an issue
    VIDEO_XILINX_HDMI21RXSS = no;  # FIXME: div64
    VIDEO_XILINX_DPRXSS = no;
    VIDEO_XILINX_HDCP1X_RX = no;
    VIDEO_XILINX_HDCP2X_RX = no;
    DRM_XLNX_HDCP = no;
    DRM_XLNX_DPTX = no;
    DRM_XLNX_HDMITX = no;
    DRM_XLNX_MIXER = no;
  };

  kernelPatches = [
    # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
    { name = "fix-tps544-nsdeps"; patch = ./fix-tps544-nsdeps.patch; }
  ] ++ lib.optionals (lib.versionAtLeast version "6.1.0-xilinx-v2023.2") [
    # ERROR: modpost: "xlnx_hdcp_tx_set_keys" [drivers/gpu/drm/xlnx/xlnx_hdmi.ko] undefined!
    # ERROR: modpost: module xlnx_mpg2tsmux uses symbol dma_buf_unmap_attachment from namespace DMA_BUF, but does not import it.
    { name = "fix-hdcp-modpost"; patch = ./fix-hdcp-modpost.patch; }
  ] ++ lib.optionals (lib.versionOlder version "6.1.0-xilinx-v2023.2") [
    # error: implicit declaration of function 'FIELD_PREP'
    { name = "xilinx-hdcp1x-cipher"; patch = ./xilinx-hdcp1x-cipher.patch; }
  # ] ++ lib.optionals stdenv.is32bit [
  #   # ERROR: modpost: "__aeabi_ldivmod" [drivers/clk/clk-xlnx-clock-wizard.ko] undefined!
  #   { name = "fix-various-xilinx-modules-div64"; patch = ./fix-various-xilinx-modules-div64.patch; }
  ] ++ kernelPatches;

  extraMeta.platforms = [ "aarch64-linux" "armv7l-linux" ];
} // (args.argsOverride or { }))
