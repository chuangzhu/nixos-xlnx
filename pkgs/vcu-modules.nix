{
  lib,
  stdenv,
  fetchFromGitHub,
  kernel,
}:

stdenv.mkDerivation (finalAttrs: {
  name = "xlnx-vcu-modules-${kernel.version}-${finalAttrs.version}";
  version = kernel.meta.xlnxVersion;

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "vcu-modules";
    rev = "xilinx_v${finalAttrs.version}";
    hash =
      {
        "2024.1" = "sha256-QR+ltPrgjcHY/nkNsXkhBsYeYwGQCOhzzzV1qtVjyzw=";
        "2025.1" = "sha256-7BQKfPz10tC5jgy9aR89u/Kc15Ee/7sXSphtxhD0bNo=";
      }
      .${kernel.meta.xlnxVersion};
  };

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ ];

  makeFlags = kernel.makeFlags ++ [
    "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installTargets = [ "modules_install" ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  enableParallelBuilding = true;

  meta = {
    description = "Out-of-tree Linux modules for Xilinx Zynq UltraScale+ Video Codec Unit (VCU)";
    homepage = "https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842546/Xilinx+Zynq+UltraScale+MPSoC+Video+Codec+Unit";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ chuangzhu ];
  };
})
