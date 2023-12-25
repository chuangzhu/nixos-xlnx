{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, armTrustedFirmwareXlnx
, ubootXlnx
, bitstream ? null # system.bit
, fsbl ? null # zynqmp_fsbl.elf
, pmufw ? null # pmufw.elf
}:

stdenv.mkDerivation {
  name = "BOOT.BIN";
  dontUnpack = true;

  nativeBuildInputs = [ xilinx-bootgen ];
  # [destination_cpu=a53-0, load=0x00100000] /mnt/xlnx/images/linux/system.dtb
  buildPhase = ''
    mkdir $out/
    bootgen -image ${writeText "bootgen.bif" ''
      the_ROM_image: {
        [bootloader, destination_cpu=a53-0] ${fsbl}
        [pmufw_image] ${pmufw}
        [destination_device=pl] ${bitstream}
        [destination_cpu=a53-0, exception_level=el-3, trustzone] ${armTrustedFirmwareXlnx}/bl31.elf
        [destination_cpu=a53-0, exception_level=el-2] ${ubootXlnx}/u-boot.elf
      }
    ''} -arch zynqmp -w -o $out/BOOT.BIN
  '';
}
