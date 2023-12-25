{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, armTrustedFirmwareXlnx
, ubootXlnx
, fsbl ? null
, pmufw ? null
}:

# assert fsbl != null;
# assert pmufw != null;

stdenv.mkDerivation {
  name = "BOOT.bin";
  dontUnpack = true;

  nativeBuildInputs = [ xilinx-bootgen ];
  buildPhase = ''
    bootgen -image ${writeText "bootgen.bif" ''
      the_ROM_image: {
        [bootloader, destination_cpu=a53-0] /mnt/xlnx/images/linux/zynqmp_fsbl.elf
        [pmufw_image] /mnt/xlnx/images/linux/pmufw.elf
        [destination_device=pl] /mnt/xlnx/project-spec/hw-description/exdes_wrapper.bit
        [destination_cpu=a53-0, exception_level=el-3, trustzone] ${armTrustedFirmwareXlnx}/bl31.elf
        [destination_cpu=a53-0, load=0x00100000] /mnt/xlnx/images/linux/system.dtb
        [destination_cpu=a53-0, exception_level=el-2] ${ubootXlnx}/u-boot.elf
      }
    ''} -arch zynqmp -w -o $out/BOOT.bin
  '';
}
