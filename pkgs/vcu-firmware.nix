{ lib, stdenvNoCC, fetchFromGitHub }:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "vcu-firmware";
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "vcu-firmware";
    rev = "xilinx_v${finalAttrs.version}";
    hash = "sha256-QR5odG6gYidWL6wbjpPZ56F1pLtMYsWyoQhOxRkvw/8=";
  };

  installPhase = ''
    runHook preInstall

    install -D -m644 1.0.0/lib/firmware/al5d.fw -t $out/lib/firmware/
    install -D -m644 1.0.0/lib/firmware/al5d_b.fw -t $out/lib/firmware/
    install -D -m644 1.0.0/lib/firmware/al5e.fw -t $out/lib/firmware/
    install -D -m644 1.0.0/lib/firmware/al5e_b.fw -t $out/lib/firmware/
    install -D -m644 LICENSE -t $out/share/xlnx-vcu-firmware/

    runHook postInstall
  '';

  dontFixup = true;

  meta = with lib; {
    description = "Firmware for Xilinx Zynq UltraScale+ Video Codec Unit (VCU)";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842546/Xilinx+Zynq+UltraScale+MPSoC+Video+Codec+Unit";
    license = licenses.unfreeRedistributableFirmware;
    sourceProvenance = with sourceTypes; [ binaryFirmware ];
    maintainers = with maintainers; [ chuangzhu ];
  };
})
