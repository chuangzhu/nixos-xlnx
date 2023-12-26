final: prev: {

  embeddedsw-xlnx = prev.callPackage ./embeddedsw.nix { };
  ubootXlnx = prev.callPackage ./u-boot-xlnx.nix { };
  armTrustedFirmwareXlnx = prev.callPackage ./arm-trusted-firmware-xlnx.nix { };
  boot-bin-xlnx = prev.callPackage ./boot-bin-xlnx.nix { };
  linux_xlnx = prev.callPackage ./linux-xlnx.nix { kernelPatches = [ ]; };
  linuxPackages_xlnx = prev.linuxKernel.packagesFor final.linux_xlnx;

  libomxil-xlnx = prev.callPackage ./libomxil-xlnx.nix { };
  libvcu-xlnx = prev.callPackage ./libvcu-xlnx.nix { };

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

}
