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
    hash = "sha256-UDz9KK/Hw3qM1BAeKif30rE8Bi6C2uvuZlvyvtJCMfw=";
  };

  meta = {
    platforms = [ "aarch64-none" "arm-none" ];
  };
})
