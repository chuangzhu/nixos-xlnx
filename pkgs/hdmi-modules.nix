{ lib, stdenv, fetchFromGitHub, kernel, kmod }:

stdenv.mkDerivation (finalAttrs: {
  name = "xlnx-hdmi-modules-${kernel.version}-${finalAttrs.version}";
  version = "2024.1";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "hdmi-modules";
    rev = "xilinx_v${finalAttrs.version}";
    hash = "sha256-YZENLz7C54yVeqbIhMnEfnS1g0lTzu8Rr1GaKH7a0Z4=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ ];

  makeFlags = kernel.makeFlags ++ [
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  # hdmi/xilinx_drm_hdmi.c #includes drivers/gpu/drm/xlnx/xlnx_bridge.h
  # But driver specific headers are removed in Nixpkgs' kernel builder
  # So a reference to kernel.src is needed
  env.NIX_CFLAGS_COMPILE = toString [ "-isystem" "${kernel.src}/drivers" ];

  installTargets = [ "modules_install" ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  enableParallelBuilding = true;

  meta = {
    description = "Out-of-tree Linux modules for Xilinx HDMI IP cores";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842136/Xilinx+DRM+KMS+HDMI-Tx+Driver";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ chuangzhu ];
  };
})
