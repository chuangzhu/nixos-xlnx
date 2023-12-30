{ lib
, stdenv
, fetchFromGitHub
}:

let
  version = "2022.2";
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "embeddedsw";
    rev = "xilinx_v${version}";
    hash = "sha256-UDz9KK/Hw3qM1BAeKif30rE8Bi6C2uvuZlvyvtJCMfw=";
  };
in

{
  zynqmp-pmufw = stdenv.mkDerivation (finalAttrs: {
    pname = "zynqmp-pmufw";
    inherit version src;

    postPatch = ''
      patchShebangs lib/sw_apps/zynqmp_pmufw/misc/copy_bsp.sh
      substituteInPlace lib/sw_apps/zynqmp_pmufw/misc/xparameters.h \
        --replace "XPAR_MICROBLAZE_USE_BARREL 1" "XPAR_MICROBLAZE_USE_BARREL 0"
    '';
    makeFlags = [
      "-C" "lib/sw_apps/zynqmp_pmufw/src"
      "CC:=$(CC)" "COMPILER=$(CC)"
      "AR:=$(AR)" "ARCHIVER=$(AR)"
    ];

    installPhase = ''
      runHook preInstall
      install -Dm555 lib/sw_apps/zynqmp_pmufw/src/executable.elf -T $out/pmufw.elf
      runHook postInstall
    '';
    dontStrip = true;

    meta = with lib; {
      description = "Zynq MPSoC Platform Management Unit firmware";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841724/PMU+Firmware";
      license = licenses.mit;
      platforms = [ "microblazeel-none" ];
      maintainer = with maintainers; [ chuangzhu ];
    };
  });

  zynqmp-fsbl = stdenv.mkDerivation (finalAttrs: {
    pname = "zynqmp-fsbl";
    inherit version src;

    postPatch = ''
      patchShebangs lib/sw_apps/zynqmp_fsbl/misc/copy_bsp.sh
    '';
    makeFlags = [
      "-C" "lib/sw_apps/zynqmp_fsbl/src"
      "CC:=$(CC)" "COMPILER=$(CC)"
      "AR:=$(AR)" "ARCHIVER=$(AR)"
      "CROSS_COMP=${stdenv.targetPlatform.config}"
    ];

    installPhase = ''
      runHook preInstall
      install -Dm555 lib/sw_apps/zynqmp_fsbl/src/fsbl.elf -t $out/
      runHook postInstall
    '';
    dontStrip = true;

    meta = with lib; {
      description = "Zynq MPSoC First Stage Boot Loader";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842019/FSBL";
      license = licenses.mit;
      platforms = [ "aarch64-none" ];
      maintainer = with maintainers; [ chuangzhu ];
    };
  });
}
