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
    sourceRoot = "source/lib/sw_apps/zynqmp_pmufw/src";

    meta = with lib; {
      description = "Zynq MPSoC Platform Management Unit firmware";
      license = licenses.mit;
      platforms = [ "microblazeel-none" ];
    };
  });

  zynqmp-fsbl = stdenv.mkDerivation (finalAttrs: {
    pname = "zynqmp-fsbl";

    meta = with lib; {
      license = licenses.mit;
      platforms = [ "aarch64-none" ];
    };
  });
}
