{ lib, stdenv, fetchurl, kernel }:

stdenv.mkDerivation (finalAttrs: {
  name = "digilent-hdmi-${kernel.version}-${finalAttrs.version}";
  version = "2022.1";

  src = fetchurl {
    url = "https://github.com/Digilent/linux-digilent/raw/refs/heads/digilent_rebase_v5.15_LTS_2022.1/drivers/gpu/drm/xlnx/digilent_hdmi.c";
    hash = "sha256-966WmpN9XVYDwo+/VQWokdhypipu+sBN2PMh6b4Tz64=";
  };

  unpackPhase = ''
    cp ${finalAttrs.src} ${finalAttrs.src.name}
    chmod u+w ${finalAttrs.src.name}
    echo 'obj-m += digilent_hdmi.o' > Makefile
  '';

  patches = [ ./digilent-hdmi.patch ];

  nativeBuildInputs = kernel.moduleBuildDependencies;

  makeFlags = kernel.makeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
  ];

  installTargets = [ "modules_install" ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  meta = {
    description = "Modularized Linux driver for Digilent rgb2dvi IP";
    homepage = "https://digilent.com/reference/programmable-logic/zybo-z7/demos/hdmi";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ chuangzhu ];
  };
})
