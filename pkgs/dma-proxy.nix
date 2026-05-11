{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags ? null,
}:

stdenv.mkDerivation rec {
  pname = "dma-proxy";
  version = "unstable-2025-06-25";

  src = fetchFromGitHub {
    owner = "Xilinx-Wiki-Projects";
    repo = "software-prototypes";
    rev = "aa646c3b7204695880848c3a060e78c9351b4f3c";
    hash = "sha256-Z31B7556x5LfffcxZDRJCQzFryiR6bTBVZUGEf+dZFI=";
  };
  sourceRoot = "source/linux-user-space-dma/Software/Kernel";

  patches = [ ./dma-proxy.patch ];

  postPatch = ''
    cp ../Common/dma-proxy.h .
    echo '
    obj-m := dma-proxy.o
    SRC := $(shell pwd)
    all:
    	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules
    install:
    	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) modules_install
    ' > Makefile
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = (if kernelModuleMakeFlags != null then kernelModuleMakeFlags else kernel.makeFlags) ++ [
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  meta = with lib; {
    description = "Xilinx's prototype application for Linux userspace DMA";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/1027702787/Linux+DMA+From+User+Space+2.0";
    license = with licenses; [
      gpl2Only
      asl20
    ];
    platforms = platforms.linux;
    maintainer = with maintainers; [ chuangzhu ];
  };

  passthru.bin = stdenv.mkDerivation {
    name = "dma-proxy-test";
    inherit version src meta;
    sourceRoot = "source/linux-user-space-dma/Software/User";
    buildPhase = "$CC dma-proxy-test.c -I../Common -o dma-proxy-test";
    installPhase = ''
      mkdir -p $out/bin
      install dma-proxy-test -t $out/bin/
    '';
  };
}
