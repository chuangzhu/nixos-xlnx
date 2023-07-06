final: prev: {

  libomxil-xlnx = final.callPackage ./libomxil-xlnx.nix { };
  libvcu-xlnx = final.callPackage ./libvcu-xlnx.nix { };

  gst_all_1 = let
    version = "1.20.5";
    src = prev.fetchFromGitHub {
      owner = "Xilinx";
      repo = "gstreamer";
      rev = "xlnx-rebase-v1.20.5_2023.1";
      hash = "sha256-M1P44WWLY/a2SWXVXgNfk55EofGRi8BzCLXjDG4mh/w=";
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
    gst-omx-zynqultrascaleplus = (final.callPackage ./gst-omx.nix { omxTarget = "zynqultrascaleplus"; }).overrideAttrs (super: {
      # inherit version; src = "${src}/subprojects/gst-omx";
      mesonFlags = super.mesonFlags ++ [ (prev.lib.mesonOption "header_path" "${final.libomxil-xlnx}/include/vcu-omx-il") ];
      postPatch = super.postPatch + ''
        substituteInPlace config/zynqultrascaleplus/gstomx.conf --replace "/usr" "${final.libomxil-xlnx}"
      '';
    });
  };

}
