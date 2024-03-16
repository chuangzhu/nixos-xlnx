final: prev: {

  inherit (prev.callPackages ./pkgs/embeddedsw.nix { })
    zynqmp-fsbl zynqmp-pmufw;
  ubootZynqMP = prev.callPackage ./pkgs/u-boot-xlnx.nix { platform = "zynqmp"; };
  ubootZynq = prev.callPackage ./pkgs/u-boot-xlnx.nix { platform = "zynq"; };
  armTrustedFirmwareZynqMP = prev.callPackage ./pkgs/arm-trusted-firmware-xlnx.nix { };
  linux_zynqmp = prev.callPackage ./pkgs/linux-xlnx { defconfig = "xilinx_defconfig"; kernelPatches = [ ]; };
  linux_zynq = prev.callPackage ./pkgs/linux-xlnx { defconfig = "xilinx_zynq_defconfig"; kernelPatches = [ ]; };
  linuxPackages_zynqmp = (prev.linuxKernel.packagesFor final.linux_zynqmp).extend final.xlnxExtraLinuxPackages;
  linuxPackages_zynq = (prev.linuxKernel.packagesFor final.linux_zynq).extend final.xlnxExtraLinuxPackages;

  xlnxExtraLinuxPackages= kfinal: kprev: {
    xlnx-hdmi-modules = kprev.callPackage ./pkgs/hdmi-modules.nix { };
    xlnx-dp-modules = kprev.callPackage ./pkgs/dp-modules.nix { };
    xlnx-vcu-modules = kprev.callPackage ./pkgs/vcu-modules.nix { };
    mali-module-xlnx = kprev.callPackage ./pkgs/mali-module-xlnx.nix { };
    xlnx-dma-proxy = kprev.callPackage ./pkgs/dma-proxy.nix { };
    bperez77-xilinx-axidma = kprev.callPackage ./pkgs/xilinx-axidma.nix { };
    jacobfeder-axisfifo = kprev.callPackage ./pkgs/axisfifo.nix { };
  };
  xlnx-vcu-firmware = prev.callPackage ./pkgs/vcu-firmware.nix { };

  libmali-xlnx = prev.callPackages ./pkgs/libmali-xlnx.nix { };
  libomxil-xlnx = prev.callPackage ./pkgs/libomxil-xlnx.nix { };
  libvcu-xlnx = prev.callPackage ./pkgs/libvcu-xlnx.nix { };

  xorg = prev.xorg // {
    xf86videoarmsoc = prev.callPackage ./pkgs/xf86-video-armsoc.nix { };
  };

  gst_all_1 = prev.gst_all_1 // {
    gst-omx-zynqultrascaleplus = (prev.callPackage ./pkgs/gst-omx.nix { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: {
      mesonFlags = super.mesonFlags ++ [ (prev.lib.mesonOption "header_path" "${final.libomxil-xlnx}/include/vcu-omx-il") ];
      postPatch = super.postPatch + ''
        substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${final.libomxil-xlnx}"
      '';
    });
  };

  gst_all_1-xlnx = with prev; recurseIntoAttrs(callPackage ./pkgs/gstreamer {
    callPackage = newScope (final.gst_all_1-xlnx // { libav = pkgs.ffmpeg; });
    inherit (final) libomxil-xlnx;
    inherit (darwin.apple_sdk.frameworks) AudioToolbox AVFoundation Cocoa CoreFoundation CoreMedia CoreServices CoreVideo DiskArbitration Foundation IOKit MediaToolbox OpenGL VideoToolbox;
  });

  xilinx-bootgen_2022_2 = prev.xilinx-bootgen.overrideAttrs rec {
    version = "xilinx_v2022.2";
    src = prev.fetchFromGitHub {
      owner = "Xilinx";
      repo = "bootgen";
      rev = version;
      hash = "sha256-bnvF0rRWvMuqeLjXfEQ9uaS1x/3iE/jLM3yoiBN0xbU=";
    };
  };
}
