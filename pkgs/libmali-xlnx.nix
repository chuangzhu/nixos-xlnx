{ lib
, stdenvNoCC
, fetchFromGitHub
, autoPatchelfHook
, libdrm
, wayland
, stdenv
, xorg
}:

let

  system = {
    aarch64-linux = "aarch64-linux-gnu";
    armv7l-linux = "arm-linux-gnueabihf";
  }.${stdenvNoCC.hostPlatform.system};

  mkMali = name: buildInputs: stdenvNoCC.mkDerivation rec {
    pname = "libmali-xlnx";
    version = "2024.1";

    outputs = [ "out" "dev" ];
    src = fetchFromGitHub {
      owner = "Xilinx";
      repo = "mali-userspace-binaries";
      rev = "xilinx_v${version}";
      hash = "sha256-xUJM3BIqEeSVX6hgxRHCwdutS8zYM/1t9UVnv7EatZU=";
    };

    nativeBuildInputs = [ autoPatchelfHook ];
    inherit buildInputs;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share/libmali-xlnx
      cp -r r9p0-01rel0/${system}/common/ $out/lib
      cp r9p0-01rel0/${system}/${name}/libMali.so.9.0 $out/lib/
      cp EULA $out/share/libmali-xlnx/
      mkdir -p $dev
      cp -r r9p0-01rel0/glesHeaders/ $dev/include
      runHook postInstall
    '';

    meta = with lib; {
      description = "EGL / OpenGLES drivers for Xilinx Mali GPUs";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841928/Xilinx+MALI+driver";
      license = licenses.unfreeRedistributable;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
      platforms = [ "aarch64-linux" "armv7l-linux" ];
      maintainers = with maintainers; [ chuangzhu ];
    };
  };

in

{
  wayland = mkMali "wayland" [
    libdrm
    wayland
    stdenv.cc.cc.lib
  ];

  x11 = mkMali "x11" [
    xorg.libX11
    libdrm
    xorg.libXfixes
    xorg.libXext
    xorg.libXdamage
  ];

  fbdev = mkMali "fbdev" [ ];

  headless = mkMali "headless" [ ];
}
