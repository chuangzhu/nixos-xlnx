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

  mkEmbeddedswApp = { template, proc, ... } @ args: stdenv.mkDerivation ({
    pname = template;
    inherit version src;

    nativeBuildInputs = [
      (buildPackages.python3.withPackages (p: [
        buildPackages.python-lopper
        p.pyyaml
        # ModuleNotFoundError: No module named 'distutils'
        p.setuptools
        p.libfdt
      ]))
      cmake
    ];

    depsBuildBuild = [ buildPackages.stdenv.cc ];  # cpp
    env.LOPPER_DTC_FLAGS = "-@";

    configurePhase = ''
      runHook preConfigure
      export ESW_REPO=$(readlink -f .)
      export BSP_DIR=$(mktemp -d)
      pushd $BSP_DIR
      python $ESW_REPO/scripts/pyesw/create_bsp.py -t ${template} -s ${sdtDir}/system-top.dts -p ${proc}
      popd
      # python $ESW_REPO/scripts/pyesw/build_bsp.py -d $BSP_DIR
      export APP_DIR=$(mktemp -d)
      pushd $APP_DIR
      python $ESW_REPO/scripts/pyesw/create_app.py -t ${template} -d $BSP_DIR
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
      install -Dm555 $APP_DIR/build/${template}.elf -t $out/
      runHook postInstall
    '';
    dontStrip = true;
  } // builtins.removeAttrs args [ "template" "proc" ]);

in

{
  zynqmp-pmufw = mkEmbeddedswApp {
    template = "zynqmp_pmufw";
    proc = "psu_pmu_0";
    postPatch = ''
      substituteInPlace cmake/toolchainfiles/microblaze-pmu_toolchain.cmake --replace-fail mb- ${stdenv.cc.targetPrefix}
    '';
    meta = {
      description = "Zynq MPSoC Platform Management Unit firmware";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18841724/PMU+Firmware";
      license = lib.licenses.mit;
      platforms = [ "microblazeel-none" ];
      maintainer = with lib.maintainers; [ chuangzhu ];
    };
  };

  zynqmp-fsbl = mkEmbeddedswApp {
    template = "zynqmp_fsbl";
    proc = "psu_cortexa53_0";
    meta = with lib; {
      description = "Zynq MPSoC First Stage Boot Loader";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842019/FSBL";
      license = licenses.mit;
      # It does also support running on the Cortex-R5 core, but I haven't tried that yet
      platforms = [ "aarch64-none" ];
      maintainer = with maintainers; [ chuangzhu ];
    };
  };

  zynq-fsbl = mkEmbeddedswApp {
    template = "zynq_fsbl";
    proc = "ps7_cortexa9_0";
    # arm-none-eabihf-
    postPatch = ''
      substituteInPlace cmake/toolchainfiles/cortexa9_toolchain.cmake --replace-fail arm-none-eabi- ${stdenv.cc.targetPrefix}
    '';
    meta = with lib; {
      description = "Zynq-7000 First Stage Boot Loader";
      homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/439124055/Zynq-7000+FSBL";
      license = licenses.mit;
      platforms = [ "arm-none" ];
      maintainer = with maintainers; [ chuangzhu ];
    };
  };
}
