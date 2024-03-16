{ lib
, stdenv
, fetchurl
, meson
, ninja
, pkg-config
, gstreamer
, gst-plugins-base
, libGL
, python3
# Could be "generic", "rpi", "bellagio", "zynqultrascaleplus", "tizonia"
, omxTarget ? "generic"
# Checks meson.is_cross_build(), so even canExecute isn't enough.
}:

stdenv.mkDerivation rec {
  pname = "gst-omx";
  version = "1.18.5";

  src = fetchurl {
    url = "https://github.com/Xilinx/gst-omx/archive/refs/tags/xlnx-rebase-v1.18.5_2022.2.tar.gz";
    sha256 = "sha256-W/tGhPWtQs2D2BaMicj53bAzx6AdQJEUsez4oa0IKQE=";
  };

  outputs = [ "out" "dev" ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ];

  buildInputs = [
    gstreamer
    gst-plugins-base
    libGL
  ];

  strictDeps = true;

  mesonFlags = [
    "-Dtarget=${omxTarget}"
    "-Ddoc=disabled"
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
