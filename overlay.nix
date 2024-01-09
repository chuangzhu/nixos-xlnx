final: prev: {

  inherit (prev.callPackages ./embeddedsw.nix { })
    zynqmp-fsbl zynqmp-pmufw;
  ubootZynqMP = prev.callPackage ./u-boot-xlnx.nix { platform = "zynqmp"; };
  ubootZynq = prev.callPackage ./u-boot-xlnx.nix { platform = "zynq"; };
  armTrustedFirmwareZynqMP = prev.callPackage ./arm-trusted-firmware-xlnx.nix { };
  boot-bin-zynqmp = prev.callPackage ./boot-bin.nix { };
  boot-bin-zynq = prev.callPackage ./boot-bin.nix { };
  linux_zynqmp = prev.callPackage ./linux-xlnx.nix { defconfig = "xilinx_defconfig"; kernelPatches = [ ]; };
  linux_zynq = prev.callPackage ./linux-xlnx.nix { defconfig = "xilinx_zynq_defconfig"; kernelPatches = [ ]; };
  linuxPackages_zynqmp = (prev.linuxKernel.packagesFor final.linux_zynqmp).extend final.xlnxExtraLinuxPackages;
  linuxPackages_zynq = (prev.linuxKernel.packagesFor final.linux_zynq).extend final.xlnxExtraLinuxPackages;

  xlnxExtraLinuxPackages= lfinal: lprev: {
    xlnx-hdmi-modules = lprev.callPackage ./hdmi-modules.nix { };
    xlnx-dp-modules = lprev.callPackage ./dp-modules.nix { };
    mali-module-xlnx = lprev.callPackage ./mali-module-xlnx.nix { };
  };

  libmali-xlnx = prev.callPackages ./libmali-xlnx.nix { };
  libomxil-xlnx = prev.callPackage ./libomxil-xlnx.nix { };
  libvcu-xlnx = prev.callPackage ./libvcu-xlnx.nix { };

  xorg = prev.xorg // {
    xf86videoarmsoc = prev.callPackage ./xf86-video-armsoc.nix { };
  };

  gst_all_1 = prev.gst_all_1 // {
    gst-omx-zynqultrascaleplus = (prev.callPackage ./gst-omx.nix { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: {
      mesonFlags = super.mesonFlags ++ [ (prev.lib.mesonOption "header_path" "${final.libomxil-xlnx}/include/vcu-omx-il") ];
      postPatch = super.postPatch + ''
        substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${final.libomxil-xlnx}"
      '';
    });
  };

  gst_all_1-xlnx = let
    version = "1.20.5";
    src = prev.applyPatches {
      src = prev.fetchFromGitHub {
        owner = "Xilinx";
        repo = "gstreamer";
        rev = "xlnx-rebase-v1.20.5_2023.1";
        hash = "sha256-M1P44WWLY/a2SWXVXgNfk55EofGRi8BzCLXjDG4mh/w=";
      };
      patches = [
        # Many pipelines fail to launch with this commit, e.g. videotestsrc ! kmssink
        # fa44de079c: good, de00c69ba7: bad
        (prev.fetchpatch {
          url = "https://github.com/Xilinx/gstreamer/commit/de00c69ba7f3e20e4db68d63a74d3090c4c77d45.patch";
          revert = true;
          hash = "sha256-wosCQwJMVC89Hbo68MKMj/2VGLDaYRbxUobvHCb/ROw=";
        })
      ];
    };
    prev' = prev.gst_all_1;
  in prev' // {
    gstreamer = prev'.gstreamer.overrideAttrs (super: { inherit version; src = "${src}/subprojects/gstreamer"; });
    gst-plugins-base = prev'.gst-plugins-base.overrideAttrs (super: { inherit version; src = "${src}/subprojects/gst-plugins-base"; });
    gst-plugins-good = prev'.gst-plugins-good.overrideAttrs (super: {
      inherit version; src = "${src}/subprojects/gst-plugins-good";
      mesonFlags = builtins.filter (x: x != "-Dqt6=disabled") super.mesonFlags;
    });
    gst-plugins-ugly = prev'.gst-plugins-ugly.overrideAttrs (super: { inherit version; src = "${src}/subprojects/gst-plugins-ugly"; });
    gst-plugins-bad = prev'.gst-plugins-bad.overrideAttrs (super: {
      inherit version; src = "${src}/subprojects/gst-plugins-bad";
      patches = builtins.filter (p: builtins.match ".*fix-paths.patch" (toString p) == null) super.patches;
      mesonFlags = builtins.filter (x: ! (prev.lib.elem x [
        "-Damfcodec=disabled" "-Ddirectshow=disabled" "-Dqsv=disabled"
      ])) super.mesonFlags ++ [ "-Dmediasrcbin=disabled" ];
    });
    gst-omx-zynqultrascaleplus = (prev.callPackage ./gst-omx.nix { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: rec {
      inherit version; src = "${src}/subprojects/gst-omx";
      # inherit version;
      # src = prev.fetchurl {
      #   url = "https://gstreamer.freedesktop.org/src/${super.pname}/${super.pname}-${version}.tar.xz";
      #   hash = "sha256-vMy8AlSM3BI/1JlE3USk8a3F0QfjbwENMg61JuIQeAY=";
      # };
      mesonFlags = super.mesonFlags ++ [ (prev.lib.mesonOption "header_path" "${final.libomxil-xlnx}/include/vcu-omx-il") ];
      postPatch = super.postPatch + ''
        substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${final.libomxil-xlnx}"
      '';
    });
  };

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
