{ xlnxVersion ? "2025.1" }: final: prev: {

  inherit (prev.callPackages ./pkgs/embeddedsw.nix { inherit xlnxVersion; })
    zynqmp-fsbl zynqmp-pmufw zynq-fsbl;
  ubootZynqMP = prev.callPackage ./pkgs/u-boot-xlnx.nix { inherit xlnxVersion; platform = "zynqmp"; };
  ubootZynq = prev.callPackage ./pkgs/u-boot-xlnx.nix { inherit xlnxVersion; platform = "zynq"; };
  armTrustedFirmwareZynqMP = prev.callPackage ./pkgs/arm-trusted-firmware-xlnx.nix { inherit xlnxVersion; };
  linux_zynqmp = prev.callPackage ./pkgs/linux-xlnx { inherit xlnxVersion; defconfig = "xilinx_defconfig"; kernelPatches = [ ]; };
  linux_zynq = prev.callPackage ./pkgs/linux-xlnx { inherit xlnxVersion; defconfig = "xilinx_zynq_defconfig"; kernelPatches = [ ]; };
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
  xlnx-vcu-firmware = prev.callPackage ./pkgs/vcu-firmware.nix { inherit xlnxVersion; };

  libmali-xlnx = prev.callPackages ./pkgs/libmali-xlnx.nix { inherit xlnxVersion; };
  libomxil-xlnx = prev.callPackage ./pkgs/libomxil-xlnx.nix { inherit xlnxVersion; };
  libvcu-xlnx = prev.callPackage ./pkgs/libvcu-xlnx.nix { inherit xlnxVersion; };

  xorg = prev.xorg // {
    xf86videoarmsoc = prev.callPackage ./pkgs/xf86-video-armsoc.nix { inherit xlnxVersion; };
  };

  gst_all_1 = prev.gst_all_1 // {
    gst-omx-zynqultrascaleplus = (prev.callPackage ./pkgs/gst-omx.nix { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: {
      mesonFlags = super.mesonFlags ++ [ (prev.lib.mesonOption "header_path" "${final.libomxil-xlnx}/include/vcu-omx-il") ];
      postPatch = super.postPatch + ''
        substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${final.libomxil-xlnx}"
      '';
    });
  };

  xilinx-bootgen_nixosxlnx = prev.xilinx-bootgen.overrideAttrs rec {
    version = "xilinx_v${xlnxVersion}";
    src = prev.fetchFromGitHub {
      owner = "Xilinx";
      repo = "bootgen";
      rev = version;
      hash = {
        "2024.1" = "sha256-/gNAqjwfaD2NWxs2536XGv8g2IyRcQRHzgLcnCr4a34=";
        "2025.1" = "sha256-VMmqNaptD6pEJDVSmmOvHcEl+5WUfwZMwxDoaiDPdxg=";
      }.${xlnxVersion};
    };
    installPhase = ''
      install -Dm755 ${if prev.lib.versionAtLeast xlnxVersion "2025.1" then "build/bin/bootgen" else "bootgen"} $out/bin/bootgen
    '';
  };
  python-lopper = prev.python3Packages.callPackage ./pkgs/lopper.nix { };
}
