{ lib, stdenv, fetchurl, kernel }:

stdenv.mkDerivation (finalAttrs: {
  name = "digilent-dynclk-${kernel.version}-${finalAttrs.version}";
  version = "2022.1";

  src = fetchurl {
    url = "https://github.com/Digilent/linux-digilent/raw/refs/heads/digilent_rebase_v5.15_LTS_2022.1/drivers/clk/clk-dglnt-dynclk.c";
    hash = "sha256-WtoDbZLXeZtAnH3/73N1KqCdI2HWi7t8yIkRN4MWdx8=";
  };

  unpackPhase = ''
    ln -sf ${finalAttrs.src} ${finalAttrs.src.name}
    echo 'obj-m += clk-dglnt-dynclk.o' > Makefile
  '';

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  installTargets = [ "modules_install" ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  meta = {
    description = "Modularized Linux driver for Digilent dynclk IP";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ chuangzhu ];
  };
})
