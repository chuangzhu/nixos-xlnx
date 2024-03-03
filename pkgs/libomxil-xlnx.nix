{ lib
, stdenv
, fetchFromGitHub
, libvcu-xlnx
}:

stdenv.mkDerivation rec {
  pname = "libomxil-xlnx";
  version = "2023.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "vcu-omx-il";
    rev = "xilinx_v${version}";
    hash = "sha256-IlYO2NLxaj8pLQwphNs27VL06KUo2ouWzrGmm0MIseM=";
  };

  postPatch = ''
    substituteInPlace core/omx_core.cpp --replace "/usr" "$out"
  '';

  EXTERNAL_INCLUDE = "${libvcu-xlnx}/include";
  EXTERNAL_LIB = "${libvcu-xlnx}/lib";

  installPhase = ''
    runHook preInstall
    install -Dm444 omx_header/*.h -t $out/include/vcu-omx-il/
    install -Dm555 bin/libOMX.allegro.{core,video_{en,de}coder}.so -t $out/lib/
    for f in $out/lib/*.so; do ln -s "$f" "$f".1; done
  '' + lib.optionalString (lib.versionAtLeast version "2023.2") ''
    install -Dm555 bin/omx_encoder.exe -T $out/bin/omx_encoder
    install -Dm555 bin/omx_decoder.exe -T $out/bin/omx_encoder
  '' + lib.optionalString (lib.versionOlder version "2023.2") ''
    install -Dm555 bin/omx_{en,de}coder -t $out/bin/
  '' + ''
    runHook postInstall
  '';

  meta = with lib; {
    description = "OpenMAX Integration Layer implementation for Xilinx Zynq UltraScale+ VCU";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842546/Xilinx+Zynq+UltraScale+MPSoC+Video+Codec+Unit";
    license = licenses.unfree; # Based on X11 license, but with two extra terms
    sourceProvenance = with sourceTypes; [ fromSource ];
    platforms = platforms.linux;
    maintainers = with maintainers; [ chuangzhu ];
  };
}
