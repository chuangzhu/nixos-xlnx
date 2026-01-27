{
  lib,
  stdenv,
  fetchurl,
  kernel,
  kernelModuleMakeFlags ? null,
  xlnxVersion ? "2025.1",
}:

stdenv.mkDerivation (finalAttrs: {
  name = "mali-modules-${kernel.version}-${finalAttrs.version}";
  version = "r9p0-01rel0";

  src = fetchurl {
    url = "https://developer.arm.com/-/media/Files/downloads/mali-drivers/kernel/mali-utgard-gpu/DX910-SW-99002-${finalAttrs.version}.tgz";
    hash = "sha256-emcSc0HRdkDB//Xa2AJY+yo3yKISG4FSX+IyfkUyzis=";
  };
  sourceRoot = "DX910-SW-99002-${finalAttrs.version}/driver/src/devicedrv/mali";

  patches =
    (
      let
        fetchYoctoPatch =
          file: hash:
          fetchurl {
            url = "https://git.yoctoproject.org/meta-xilinx/plain/meta-xilinx-core/recipes-graphics/mali/kernel-module-mali/${file}.patch?h=ff9288d64f0b44b88c00ecb0862caa964d984fa9";
            inherit hash;
          };
      in
      [
        (fetchYoctoPatch "0001-Change-Makefile-to-be-compatible-with-Yocto" "sha256-oZY7437iXskpLwNUudpx7xded2k0DMBTHeeIPCXgKxw=")
        (fetchYoctoPatch "0002-staging-mali-r8p0-01rel0-Add-the-ZYNQ-ZYNQMP-platfor" "sha256-FMRNXNDf54/7mXVRojgfBSeMx6kiyA6ka/SiwjJul+I=")
        (fetchYoctoPatch "0003-staging-mali-r8p0-01rel0-Remove-unused-trace-macros" "sha256-gz41V0S9GtaVcSg9YctaGX6WzdNMBAB4LI3NFcFdY78=")
        (fetchYoctoPatch "0004-staging-mali-r8p0-01rel0-Don-t-include-mali_read_phy" "sha256-MJx+TdAnD4h5r1bj3v4UKTZr8boZ0+m17QPLS/DrUkU=")
        (fetchYoctoPatch "0005-linux-mali_kernel_linux.c-Handle-clock-when-probed-a" "sha256-D5z//VwkfQ10VHuLSxXDujWvnl/B6EN07s8AKZDqb18=")
        (fetchYoctoPatch "0006-arm.c-global-variable-dma_ops-is-removed-from-the-ke" "sha256-rlE8bfxWQMcS7hAjShvgx+CowDQCXHibZRH+meriH9o=")
        (fetchYoctoPatch "0010-common-mali_pm.c-Add-PM-runtime-barrier-after-removi" "sha256-oYDMJbcMOJQ1tT6IicF8mDHaFdlLQIp0nkQnPM3HjEw=")
        (fetchYoctoPatch "0011-linux-mali_kernel_linux.c-Enable-disable-clock-for-r" "sha256-5CyEMIajxOYtae086yvgjrdWGjIKk4Ezz0kd0BgaLU0=")
        (fetchYoctoPatch "0012-linux-mali_memory_os_alloc-Remove-__GFP_COLD" "sha256-+8lOrch+alzNGfLwrwfrZZK2YGNTPXvFpPNe+zgMk38=")
        (fetchYoctoPatch "0013-linux-mali_memory_secure-Add-header-file-dma-direct." "sha256-eMb1XHjZ2O62DMHKsC5Nfr8A3ul4BzuC5QPtyCF0Vbc=")
        (fetchYoctoPatch "0014-linux-mali_-timer-Get-rid-of-init_timer" "sha256-F798OUUhnL1mhuX4HZE10LdLRqz7ecI9AU/17Z/ng+4=")
        (fetchYoctoPatch "0015-fix-driver-failed-to-check-map-error" "sha256-Lt1NCC7nJfYChR90wi+V0BkMOPxOEphW4Ran0o+KhtQ=")
        (fetchYoctoPatch "0016-mali_memory_secure-Kernel-5.0-onwards-access_ok-API-" "sha256-CO5Bj19qg+Kzc4S27YeRW1EnBhKV/gGAHKeDEU7XCBY=")
        (fetchYoctoPatch "0017-Support-for-vm_insert_pfn-deprecated-from-kernel-4.2" "sha256-uDIBiO02vRLvfUThWl+sTvFEFoLHdsUh8ldfFS23T14=")
        (fetchYoctoPatch "0018-Change-return-type-to-vm_fault_t-for-fault-handler" "sha256-d/e3Id67wnQzXUy2QKh+VGtTMXOXPTv+ACnxa5Eh3F4=")
        (fetchYoctoPatch "0019-get_monotonic_boottime-ts-deprecated-from-kernel-4.2" "sha256-2vgtSN2AWBoGFbx8Jh0LjEO7DnnbwHQl4F+g1fuxo18=")
        (fetchYoctoPatch "0020-Fix-ioremap_nocache-deprecation-in-kernel-5.6" "sha256-WabhxBwGwDgVxu9u3+qh2J2Un+C4qJThxDFkC22rVE0=")
        (fetchYoctoPatch "0021-Use-updated-timekeeping-functions-in-kernel-5.6" "sha256-A9nTKBSZC2w+pithv+9orxMHuEQ5dr3CHEQhckz6CgQ=")
        (fetchYoctoPatch "0022-Set-HAVE_UNLOCKED_IOCTL-default-to-true" "sha256-GHfta8tXGkqX39QtQ+LkQXdL2OFiOQ5bbIp+Z0fUZgs=")
        (fetchYoctoPatch "0023-Use-PTR_ERR_OR_ZERO-instead-of-PTR_RET" "sha256-Fa3CjqahjhO+J2vxFgtFyWOiMKTIbbn3A46S9n3Nt2k=")
        (fetchYoctoPatch "0024-Use-community-device-tree-names" "sha256-ksnMAtvSOzW9D5u30jaBJR14gQUM+jp5t/VXE9vhOJM=")
        (fetchYoctoPatch "0025-Import-DMA_BUF-module-and-update-register_shrinker-f" "sha256-RDZ0AeyMEUNpDWQjYAkncXEsDTfVRS7MO4nF+wT7UN0=")
        (fetchYoctoPatch "0026-Fix-gpu-driver-probe-failure" "sha256-EGCxyFTdTBC8LbIM3Y+Byx4HdFkPxtjOxy6/xOP0gU0=")
        (fetchYoctoPatch "0027-Updated-clock-name-and-structure-to-match-LIMA-drive" "sha256-z6yHGkokFnTsi12FNWOky3xZGdJXpbZIrxz53ZBoTS0=")
        (fetchYoctoPatch "0028-Replace-vma-vm_flags-direct-modifications-with-modif" "sha256-BvYaYe1VSzNiY1RPVJWW0fbjK7kAJv3B/tFcxBg89CA=")
        (fetchYoctoPatch "0029-Fixed-buildpath-QA-warning" "sha256-O5cG2zXmExocea5yZL6ZoLL975uNWpBnBRLBB3zAKEk=")
      ]
    )
    ++ lib.optionals (lib.versionAtLeast xlnxVersion "2025.1") [
      (fetchurl {
        url = "https://github.com/Xilinx/meta-xilinx/raw/936845b97ab1ff035108f219f4e7cfef5401eb02/meta-xilinx-mali400/recipes-graphics/mali/kernel-module-mali/0030-Update-driver-to-make-it-compatible-with-6.12-kernel.patch";
        hash = "sha256-TbzN1KWEYxo/MJegMvfS2MXXwG/b9asXqYJmptGNxMU=";
      })
    ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ ];

  makeFlags = (if kernelModuleMakeFlags != null then kernelModuleMakeFlags else kernel.makeFlags) ++ [
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installTargets = [ "modules_install" ];
  installFlags = [ "INSTALL_MOD_PATH=$(out)" ];

  enableParallelBuilding = true;

  meta = {
    description = "Open Source Mali Utgard GPU Kernel Drivers";
    homepage = "https://developer.arm.com/downloads/-/mali-drivers/utgard-kernel";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ chuangzhu ];
  };
})
