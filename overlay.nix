final: prev: {

  inherit (prev.callPackages ./pkgs/embeddedsw.nix { })
    zynqmp-fsbl zynqmp-pmufw zynq-fsbl;
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
    digilent-hdmi = kprev.callPackage ./pkgs/digilent-hdmi.nix { };
    digilent-dynclk = kprev.callPackage ./pkgs/digilent-dynclk.nix { };
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

  xilinx-bootgen_2024_1 = prev.xilinx-bootgen.overrideAttrs rec {
    version = "xilinx_v2024.1";
    src = prev.fetchFromGitHub {
      owner = "Xilinx";
      repo = "bootgen";
      rev = version;
      hash = "sha256-/gNAqjwfaD2NWxs2536XGv8g2IyRcQRHzgLcnCr4a34=";
    };
  };
  python-lopper = prev.python3Packages.callPackage ./pkgs/lopper.nix { };
}
