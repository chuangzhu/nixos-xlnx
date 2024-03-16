{ stdenv
, fetchurl
, fetchpatch
, meson
, ninja
, pkg-config
, gettext
, gobject-introspection
, bison
, flex
, python3
, glib
, makeWrapper
, libcap
, libunwind
, darwin
, elfutils # for libdw
, bash-completion
, lib
, CoreServices
}:

stdenv.mkDerivation rec {
  pname = "gstreamer";
  version = "1.18.5";

  outputs = [
    "out"
    "dev"
    # "devdoc" # disabled until `hotdoc` is packaged in nixpkgs, see:
    # - https://github.com/NixOS/nixpkgs/pull/98767
    # - https://github.com/NixOS/nixpkgs/issues/98769#issuecomment-702296551
  ];
  outputBin = "dev";

  src = fetchurl {
    url = "https://github.com/Xilinx/gstreamer/archive/refs/tags/xlnx-rebase-v1.18.5_2022.2.tar.gz";
    sha256 = "sha256-NX1heNDXGK64KrtiPBR/5S8p9wKrDXfAjECVrCVRVX4=";
  };

  patches = [
    ./fix_pkgconfig_includedir.patch
    # Fix device discovery failing without pulseaudio
    # (Remove once version > 1.19.3)
    # https://gitlab.freedesktop.org/gstreamer/gstreamer/-/merge_requests/679
    (fetchpatch {
      url = "https://gitlab.freedesktop.org/gstreamer/gstreamer/-/commit/41677a526b83bb2493087af1d93b50c297cf97cd.patch";
      sha256 = "e5SCjRREIQ2Y1/SK8ywW/Q+ejxuWkJ7eMR4M0/wQCFs=";
    })
    # https://gitlab.freedesktop.org/gstreamer/gstreamer/-/merge_requests/1189
    (fetchpatch {
      url = "https://gitlab.freedesktop.org/gstreamer/gstreamer/-/commit/1912bcbcc42e8ee2c4948511619219f5722631d2.patch";
      stripLen = 3;
      extraPrefix = "";
      sha256 = "a1EcW0phtXjjoC4PaHGrNB9+SVHSTq8bdQbpyspp/zM=";
    })
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    gettext
    bison
    flex
    python3
    makeWrapper
    glib
    gobject-introspection
    bash-completion

    # documentation
    # TODO add hotdoc here
  ];

  buildInputs = [
    bash-completion
  ] ++ lib.optionals stdenv.isLinux [
    libcap
    libunwind
    elfutils
  ] ++ lib.optionals stdenv.isDarwin [
    CoreServices
  ];

  propagatedBuildInputs = [
    glib
  ];

  mesonFlags = [
    "-Ddbghelp=disabled" # not needed as we already provide libunwind and libdw, and dbghelp is a fallback to those
    "-Dexamples=disabled" # requires many dependencies and probably not useful for our users
    "-Ddoc=disabled" # `hotdoc` not packaged in nixpkgs as of writing
  ] ++ lib.optionals (stdenv.buildPlatform != stdenv.hostPlatform) [
    "-Dintrospection=disabled"
  ] ++ lib.optionals stdenv.isDarwin [
    # darwin.libunwind doesn't have pkg-config definitions so meson doesn't detect it.
    "-Dlibunwind=disabled"
    "-Dlibdw=disabled"
  ];

  postPatch = ''
    patchShebangs \
      gst/parse/get_flex_version.py \
      gst/parse/gen_grammar.py.in \
      gst/parse/gen_lex.py.in \
      libs/gst/helpers/ptp_helper_post_install.sh \
      scripts/extract-release-date-from-doap-file.py
  '';

  postInstall = ''
    for prog in "$dev/bin/"*; do
        # We can't use --suffix here due to quoting so we craft the export command by hand
        wrapProgram "$prog" --run 'export GST_PLUGIN_SYSTEM_PATH_1_0=$GST_PLUGIN_SYSTEM_PATH_1_0''${GST_PLUGIN_SYSTEM_PATH_1_0:+:}$(unset _tmp; for profile in $NIX_PROFILES; do _tmp="$profile/lib/gstreamer-1.0''${_tmp:+:}$_tmp"; done; printf '%s' "$_tmp")'
    done
  '';

  preFixup = ''
    moveToOutput "share/bash-completion" "$dev"
  '';

  setupHook = ./setup-hook.sh;

  meta = with lib ;{
    description = "Open source multimedia framework";
    homepage = "https://gstreamer.freedesktop.org";
    license = licenses.lgpl2Plus;
    platforms = platforms.unix;
    maintainers = with maintainers; [ ttuegel matthewbauer ];
  };
}
