{ lib, stdenv, fetchFromGitHub, fetchpatch, kernel, which, doxygen }:

stdenv.mkDerivation {
  name = "xilinx_axidma";
  outputs = [ "out" "bin" "dev" "devdoc" "drivers" ];

  src = fetchFromGitHub {
    owner = "bperez77";
    repo = "xilinx_axidma";
    rev = "42ed91e83bc4da1e29149b2be0c6a6b8f4549222";
    hash = "sha256-Mmd7CLYskk2vqbhE7rQE3VGCpE+KyJPyLRMOoi63MoY=";
  };
  patches = [
    (fetchpatch {
      url = "https://github.com/andrewvoznytsa/xilinx_axidma/commit/a87240b08b61f5c8f8964318f73d249adcc6e9ce.patch";
      hash = "sha256-pNuIPj9s5R0P7x65+6+22dg9VZLBRegyJe94g6KmPU4=";
    })
  ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ which doxygen ];
  makeFlags = kernel.makeFlags ++ [
    "KBUILD_DIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  NIX_CFLAGS_COMPILE = "-Wno-error";

  postBuild = ''
    doxygen libaxidma.dox
  '';

  installPhase = ''
    runHook preInstall
    install -Dm555 outputs/libaxidma.so -t $out/lib/
    install -Dm555 outputs/axidma_benchmark -t $bin/bin/
    install -Dm555 outputs/axidma_display_image -t $bin/bin/
    install -Dm555 outputs/axidma_transfer -t $bin/bin/
    install -Dm444 include/axidma_ioctl.h -t $dev/include/
    install -Dm444 include/libaxidma.h -t $dev/include/
    install -Dm444 outputs/axidma.ko -t $drivers/lib/modules/${kernel.modDirVersion}/extra/
    runHook postInstall
  '';

  postFixup = ''
    # Cannot be in postInstall, otherwise _multioutDocs hook in preFixup will move right back.
    mkdir -p $devdoc/share/doc/
    cp -r docs/html $devdoc/share/doc/xilinx_axidma
  '';

  meta = with lib; {
    description = "Zero-copy Linux driver and userspace interface library for Xilinx's AXI DMA and VDMA IP blocks";
    homepage = "https://github.com/bperez77/xilinx_axidma";
    license = with licenses; [ gpl2Only mit ];
    platforms = platforms.linux;
    maintainer = with maintainers; [ chuangzhu ];
  };
}
