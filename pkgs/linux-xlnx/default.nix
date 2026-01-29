{
  lib,
  buildLinux,
  fetchFromGitHub,
  stdenv,
  defconfig ? "xilinx_defconfig",
  kernelPatches ? [ ],
  xlnxVersion ? "2025.1",
  ...
}@args:

let
  throwVersion = throw "Unsupported xlnxVersion: ${xlnxVersion}";

  # Check linux/Makefile
  linuxVersion =
    {
      # "2022.2" = "5.15.0";
      # "2023.2" = "6.1.30";
      "2024.1" = "6.6.10";
      "2025.1" = "6.12.60";
    }
    .${xlnxVersion} or throwVersion;

  version = "${linuxVersion}-xilinx-v${xlnxVersion}";
in

buildLinux (
  args
  // {
    inherit version;
    modDirVersion =
      if defconfig == "xilinx_zynq_defconfig" then "${linuxVersion}-xilinx" else linuxVersion;
    extraMeta.xlnxVersion = xlnxVersion;

    src = fetchFromGitHub {
      owner = "Xilinx";
      repo = "linux-xlnx";
      rev =
        {
          "2022.2" = "xilinx-v2022.2";
          "2023.2" = "a19da02cf5b44420ec6afb1eef348c21d9e8cda2"; # xlnx_rebase_v6.1_LTS
          "2024.1" = "xlnx_rebase_v6.6_LTS_2024.1";
          "2025.1" = "xlnx_rebase_v6.12_LTS_2025.1_update_merge_6.12.60";
        }
        .${xlnxVersion};
      hash =
        {
          "2022.2" = "sha256-8iPAKyK+jPkjl1TWn+IbiHN9iRyuWFivp/MeCEsNVlM=";
          "2023.2" = "sha256-gYZQLauQ/Sa2AnJdLdcWKwfQqDqctmllMDj0Rjz3qm8=";
          "2024.1" = "sha256-tfpNLRtC9OQZfWaLkaGM42bqhLICDPeT5AoE271p3a0=";
          "2025.1" = "sha256-O7gN30s35tVYfhdKaGQ5z1AR19NMsYz5LtrXt8fSgzc=";
        }
        .${xlnxVersion};
    };

    structuredExtraConfig =
      with lib.kernel;
      {
        DEBUG_INFO_BTF = lib.mkForce no;
        CRYPTO_DEV_XILINX_ECDSA = no; # Error: modpost: "ecdsasignature_decoder" undefined!
        MMC_BLOCK = yes;
        RPMB = no; # MMC_BLOCK depends on RPMB || !RPMB, so must be yes or no, not module
      }
      // lib.optionalAttrs (defconfig == "xilinx_zynq_defconfig") {
        DRM_XLNX_BRIDGE = yes; # DRM_XLNX uses xlnx_bridge_helper_init
        USB_XHCI_PLATFORM = no; # USB_XHCI_PLATFORM uses dwc3_host_wakeup_capable
        USB_XHCI_HCD = no;
        USB_DWC3 = no;
        USB_CDNS_SUPPORT = no;
      }
      // lib.optionalAttrs stdenv.is32bit {
        # Disable HDCP on Zynq7 to avoid hard-to-fix compilation errors
        # These are only relevant to XC7Z045 and XC7Z100 anyway
        # For other Zynq7 devices, use https://digilent.com/reference/programmable-logic/zybo-z7/demos/hdmi instead
        # If you are using XC7Z045 or XC7Z100 and do want to use these features, please open an issue
        VIDEO_XILINX_HDMI21RXSS = no; # FIXME: div64
        VIDEO_XILINX_DPRXSS = no;
        VIDEO_XILINX_HDCP1X_RX = no;
        VIDEO_XILINX_HDCP2X_RX = no;
        DRM_XLNX_HDCP = no;
        DRM_XLNX_DPTX = no;
        DRM_XLNX_HDMITX = no;
        DRM_XLNX_MIXER = no;
      };

    kernelPatches =
      lib.optionals (lib.versionOlder version "6.12.0-xilinx-v2025.1") [
        # ERROR: modpost: module tps544 uses symbol pmbus_do_probe from namespace PMBUS, but does not import it.
        {
          name = "fix-tps544-nsdeps";
          patch = ./fix-tps544-nsdeps.patch;
        }
      ]
      ++
        lib.optionals
          (
            lib.versionAtLeast version "6.1.0-xilinx-v2023.2"
            && lib.versionOlder version "6.12.0-xilinx-v2025.1"
          )
          [
            # ERROR: modpost: "xlnx_hdcp_tx_set_keys" [drivers/gpu/drm/xlnx/xlnx_hdmi.ko] undefined!
            # ERROR: modpost: module xlnx_mpg2tsmux uses symbol dma_buf_unmap_attachment from namespace DMA_BUF, but does not import it.
            {
              name = "fix-hdcp-modpost";
              patch = ./fix-hdcp-modpost.patch;
            }
          ]
      ++ lib.optionals (lib.versionOlder version "6.1.0-xilinx-v2023.2") [
        # error: implicit declaration of function 'FIELD_PREP'
        {
          name = "xilinx-hdcp1x-cipher";
          patch = ./xilinx-hdcp1x-cipher.patch;
        }
        # ] ++ lib.optionals stdenv.is32bit [
        #   # ERROR: modpost: "__aeabi_ldivmod" [drivers/clk/clk-xlnx-clock-wizard.ko] undefined!
        #   { name = "fix-various-xilinx-modules-div64"; patch = ./fix-various-xilinx-modules-div64.patch; }
      ]
      ++ lib.optionals (lib.versionAtLeast version "6.12.0-xilinx-v2025.1") [
        {
          name = "fix-pl_disp-fortify";
          patch = ./2025.1/fix-pl_disp-fortify.patch;
        }
      ]
      ++ kernelPatches;

    extraMeta.platforms = [
      "aarch64-linux"
      "armv7l-linux"
    ];

    ignoreConfigErrors = true;
  }
  // (args.argsOverride or { })
)
