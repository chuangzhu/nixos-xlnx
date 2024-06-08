{ lib
, stdenv
, fetchFromGitHub
, python3
, python-lopper
, cmake
, sdtDir ? null
}:

let
  version = "2024.1";
  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "embeddedsw";
    rev = "xilinx_v${version}";
    hash = "sha256-vh7tdHNd3miDZplTiRP8UWhQ/HLrjMcbQXCJjTO4p9o=";
  };
  python = python3.withPackages (p: [ python-lopper p.pyyaml ]);
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

    nativeBuildInputs = [ python cmake ];

    postPatch = ''
      patchShebangs lib/sw_apps/zynqmp_fsbl/misc/copy_bsp.sh
    '';

    configurePhase = ''
      runHook preConfigure
      export ESW_REPO=$(readlink -f .)
      export BSP_DIR=$(mktemp -d)
      pushd $BSP_DIR
      $CPP -nostdinc -undef -x assembler-with-cpp ${sdtDir}/system-top.dts -o combined.dts
      # Compile and decompile it to get the __symbols__ label node
      dtc -@ -I dts -O dtb combined.dts -o combined.dtb
      dtc -I dtb -O dts combined.dtb -o with-symbols.dts
      python $ESW_REPO/scripts/pyesw/create_bsp.py -t zynqmp_fsbl -s with-symbols.dts -p psu_cortexa53_0
      popd
      python $ESW_REPO/scripts/pyesw/build_bsp.py -d $BSP_DIR
      export APP_DIR=$(mktemp -d)
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/create_bsp.py -t zynqmp_fsbl -d $BSP_DIR
      python $ESW_REPO/scripts/pyesw/build_bsp.py
      popd
      runHook postConfigure
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
      # It does also support running on the Cortex-R5 core, but I haven't tried that yet
      platforms = [ "aarch64-none" ];
      maintainer = with maintainers; [ chuangzhu ];
    };
  });
}
