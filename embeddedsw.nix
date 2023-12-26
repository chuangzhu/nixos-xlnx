{ lib
, stdenv
, fetchFromGitHub
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "embeddedsw";
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "embeddedsw";
    rev = "xilinx_v${finalAttrs.version}";
    #hash = "";
  };

  meta = {
    platforms = [ "aarch64-none" "arm-none" ];
  };
})
