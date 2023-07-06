{ lib, stdenv
, fetchurl
, meson
, ninja
, pkg-config
, gst_all_1
, libGL
, python3
# Could be "generic", "rpi", "bellagio", "zynqultrascaleplus", "tizonia"
, omxTarget ? "generic"
# Checks meson.is_cross_build(), so even canExecute isn't enough.
, enableDocumentation ? stdenv.hostPlatform == stdenv.buildPlatform, hotdoc
}:

stdenv.mkDerivation rec {
  pname = "gst-omx";
  version = "1.22.3";

  src = fetchurl {
    url = "https://gstreamer.freedesktop.org/src/${pname}/${pname}-${version}.tar.xz";
    hash = "sha256-b1HCMxwzRZPCw88S6fIrnjtBmjJHz7L+wOG9hFVphjo=";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ] ++ lib.optionals enableDocumentation [
    hotdoc
  ];

  buildInputs = [
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libGL
  ];

  strictDeps = true;

  mesonFlags = [
    (lib.mesonOption "target" omxTarget)
    (lib.mesonEnable "doc" enableDocumentation)
  ];

  postPatch = ''
    patchShebangs \
      scripts/extract-release-date-from-doap-file.py
  '';

  meta = with lib; {
    description = "OpenMAX-based decoder and encoder elements for GStreamer";
    homepage = "https://gstreamer.freedesktop.org";
    license = licenses.lgpl21Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ chuangzhu ];
  };
}
