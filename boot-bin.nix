{ lib
, fetchFromGitHub
, writeText
, xilinx-bootgen
, stdenv
, runCommand
, armTrustedFirmwareZynqMP
, ubootZynqMP
, ubootZynq
, platform ? "zynqmp"
, bitstream ? null # system.bit
, fsbl ? null # fsbl_a53.elf
, pmufw ? null # pmufw.elf
, dtb ? null # system.dtb
}:

let
  bif = {
    zynqmp = ''
      the_ROM_image: {
        [bootloader, destination_cpu=a53-0] ${fsbl}
        [pmufw_image] ${pmufw}
        [destination_device=pl] ${bitstream}
        [destination_cpu=a53-0, exception_level=el-3, trustzone] ${armTrustedFirmwareZynqMP}/bl31.elf
        [destination_cpu=a53-0, load=0x00100000] ${dtb}
        [destination_cpu=a53-0, exception_level=el-2] ${ubootZynqMP}/u-boot.elf
      }
    '';
    zynq = ''
      the_ROM_image: {
        [bootloader] ${fsbl}
        ${bitstream}
        ${ubootZynq}/u-boot.elf
        [load=0x00100000] ${dtb}
      }
    '';
  }.${platform};
in

runCommand "BOOT.BIN" {
  nativeBuildInputs = [ xilinx-bootgen ];
} ''
  bootgen -image ${writeText "bootgen.bif" bif} -arch ${platform} -w -o $out
''
