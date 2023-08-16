{ lib
, fetchFromGitHub
, buildUBoot
, writeText
, xilinx-bootgen
}:

let
  bifFile = writeText "bootgen.bif" ''
    the_ROM_image:
    {
            [bootloader, destination_cpu=a53-0] /mnt/xlnx/images/linux/zynqmp_fsbl.elf
            [pmufw_image] /mnt/xlnx/images/linux/pmufw.elf
            [destination_device=pl] /mnt/xlnx/project-spec/hw-description/exdes_wrapper.bit
            [destination_cpu=a53-0, exception_level=el-3, trustzone] /mnt/xlnx/images/linux/bl31.elf
            [destination_cpu=a53-0, load=0x00100000] /mnt/xlnx/images/linux/system.dtb
            [destination_cpu=a53-0, exception_level=el-2] /mnt/xlnx/images/linux/u-boot.elf
    }
  '';
in

buildUBoot {
  version = "2022.2";

  src = fetchFromGitHub {
    owner = "Xilinx";
    repo = "u-boot-xlnx";
    rev = "xilinx-v2022.2";
    hash = "sha256-k8Uu9/X95L7r6OfrK7mo4ogTa872yeK7a+by/ryZc4I=";
  };

  defconfig = "xilinx_zynqmp_mini_defconfig";
  extraMeta.platforms = [ "aarch64-linux" ];

  filesToInstall = [ "boot.scr" "u-boot.elf" ];
  postBuild = ''
    ./tools/mkimage -c none -A arm -T script -d ${./boot.cmd} boot.scr
    # bootgen -image ${bifFile} -arch zynqmp -w -o BOOT.bin
  '';
}

