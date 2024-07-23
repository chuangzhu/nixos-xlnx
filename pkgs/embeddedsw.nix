{ lib
, stdenv
, fetchFromGitHub
, buildPackages
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
  python = buildPackages.python3.withPackages (p: [
    buildPackages.python-lopper
    p.pyyaml
    # ModuleNotFoundError: No module named 'distutils'
    p.setuptools
    p.libfdt
  ]);
in

{
  zynqmp-pmufw = stdenv.mkDerivation (finalAttrs: {
    pname = "zynqmp-pmufw";
    inherit version src;

    depsBuildBuild = [ buildPackages.stdenv.cc ];  # cpp

    nativeBuildInputs = [
      python
      cmake
    ];

    env.LOPPER_DTC_FLAGS = "-@";

    postPatch = ''
      substituteInPlace cmake/toolchainfiles/microblaze-pmu_toolchain.cmake --replace-fail mb- ${stdenv.cc.targetPrefix}

    '';

    configurePhase = ''
      runHook preConfigure
      export ESW_REPO=$(readlink -f .)
      export BSP_DIR=$(mktemp -d)
      pushd $BSP_DIR
      python $ESW_REPO/scripts/pyesw/create_bsp.py -t zynqmp_pmufw -s ${sdtDir}/system-top.dts -p psu_pmu_0
      popd
      # python $ESW_REPO/scripts/pyesw/build_bsp.py -d $BSP_DIR
      export APP_DIR=$(mktemp -d)
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/create_app.py -t zynqmp_pmufw -d $BSP_DIR
      popd
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/build_app.py
      popd
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm555 $APP_DIR/build/zynqmp_pmufw.elf -t $out/
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

    depsBuildBuild = [ buildPackages.stdenv.cc ];  # cpp

    nativeBuildInputs = [
      python
      cmake
    ];

    env.LOPPER_DTC_FLAGS = "-@";

    configurePhase = ''
      runHook preConfigure
      export ESW_REPO=$(readlink -f .)
      export BSP_DIR=$(mktemp -d)
      pushd $BSP_DIR
      python $ESW_REPO/scripts/pyesw/create_bsp.py -t zynqmp_fsbl -s ${sdtDir}/system-top.dts -p psu_cortexa53_0
      popd
      # python $ESW_REPO/scripts/pyesw/build_bsp.py -d $BSP_DIR
      export APP_DIR=$(mktemp -d)
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/create_app.py -t zynqmp_fsbl -d $BSP_DIR
      popd
      runHook postConfigure
    '';

    buildPhase = ''
      runHook preBuild
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/build_app.py
      popd
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm555 $APP_DIR/build/zynqmp_fsbl.elf -t $out/
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
