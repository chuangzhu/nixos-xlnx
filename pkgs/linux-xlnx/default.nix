{ lib
, buildLinux
, fetchFromGitHub
, stdenv
, defconfig ? "xilinx_defconfig"
, kernelPatches ? [ ]
, version ? "6.1.0-xilinx-v2023.2"
, ...
} @ args:

buildLinux (args // {
  inherit version;
  modDirVersion = if defconfig == "xilinx_zynq_defconfig" then "6.1.30-xilinx" else "6.1.30";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "linux-xlnx";
    rev = "a19da02cf5b44420ec6afb1eef348c21d9e8cda2";  # xlnx_rebase_v6.1_LTS
    hash = "sha256-gYZQLauQ/Sa2AnJdLdcWKwfQqDqctmllMDj0Rjz3qm8=";
  };

  structuredExtraConfig = with lib.kernel; {
    DEBUG_INFO_BTF = lib.mkForce no;
  } // lib.optionalAttrs (defconfig == "xilinx_zynq_defconfig") {
    DRM_XLNX_BRIDGE = yes;  # DRM_XLNX uses xlnx_bridge_helper_init
    USB_XHCI_PLATFORM = no;  # USB_XHCI_PLATFORM uses dwc3_host_wakeup_capable
    USB_XHCI_HCD = no;
    USB_DWC3 = no;
    USB_CDNS_SUPPORT = no;
  } // lib.optionalAttrs stdenv.is32bit {
    VIDEO_XILINX_HDMI21RXSS = no;  # FIXME: div64
  };

  kernelPatches = [
    # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
    { name = "fix-tps544-nsdeps"; patch = ./fix-tps544-nsdeps.patch; }
  ] ++ lib.optionals (lib.versionAtLeast version "6.1.0-xilinx-v2023.2") [
    # https://support.xilinx.com/s/article/000035732?language=en_US
    { name = "drm-xlnx-hdmi-Add-support-for-AVI-infoframes"; patch = ./ar000035732/0001-drm-xlnx-hdmi-Add-support-for-AVI-infoframes.patch; }
    { name = "drm-xlnx-hdmi-Add-YUV420-support"; patch = ./ar000035732/0002-drm-xlnx-hdmi-Add-YUV420-support.patch; }
    # { name = "arm64-configs-Enable-CONFIG_DRM_XLNX_HDMITX-for-zynq"; patch = ./ar000035732/0003-arm64-configs-Enable-CONFIG_DRM_XLNX_HDMITX-for-zynq.patch; }
    # { name = "arm64-configs-Enable-CONFIG_VIDEO_XILINX_HDMI21RXSS-"; patch = ./ar000035732/0004-arm64-configs-Enable-CONFIG_VIDEO_XILINX_HDMI21RXSS-.patch; }
    { name = "drm-xlnx-hdmi-Force-the-driver-to-work-only-in-TMDS-"; patch = ./ar000035732/0005-drm-xlnx-hdmi-Force-the-driver-to-work-only-in-TMDS-.patch; }
    # ERROR: modpost: "xlnx_hdcp_tx_set_keys" [drivers/gpu/drm/xlnx/xlnx_hdmi.ko] undefined!
    # ERROR: modpost: module xlnx_mpg2tsmux uses symbol dma_buf_unmap_attachment from namespace DMA_BUF, but does not import it.
    { name = "fix-hdcp-modpost"; patch = ./fix-hdcp-modpost.patch; }
  ] ++ lib.optionals (lib.versionOlder version "6.1.0-xilinx-v2023.2") [
    # error: implicit declaration of function 'FIELD_PREP'
    { name = "xilinx-hdcp1x-cipher"; patch = ./xilinx-hdcp1x-cipher.patch; }
  ] ++ lib.optionals stdenv.is32bit [
    # ERROR: modpost: "__aeabi_ldivmod" [drivers/clk/clk-xlnx-clock-wizard.ko] undefined!
    { name = "fix-various-xilinx-modules-div64"; patch = ./fix-various-xilinx-modules-div64.patch; }
  ] ++ kernelPatches;

  extraMeta.platforms = [ "aarch64-linux" "armv7l-linux" ];
} // (args.argsOverride or { }))
