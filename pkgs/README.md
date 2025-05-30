Besides the packages supporting boot, this repo contains some other useful packages. Check the `meta` fields in these packages for more information.

* [`pkgs.zynqmp-fsbl`, `pkgsCross.pmu.zynqmp-pmufw`](./embeddedsw.nix): System-device-tree flow support packages
* [`pkgs.gst_all_1.gst-omx-zynqultrascaleplus`](./gst-omx.nix)
* [`config.boot.kernelPackages.xlnx-hdmi-modules`](./hdmi-modules.nix), [`config.boot.kernelPackages.xlnx-dp-modules`](./dp-modules.nix)
* [`config.boot.kernelPackages.xlnx-vcu-modules`](./vcu-modules.nix), [`pkgs.xlnx-vcu-firmware`](./vcu-firmware.nix)
* [`config.boot.kernelPackages.xlnx-dma-proxy`](./dma-proxy.nix): Xilinx's DMA client driver
* [`config.boot.kernelPackages.bperez77-xilinx-axidma.drivers`](./xilinx-axidma.nix): Another DMA client driver, IMHO better than Xilinx's
* [`config.boot.kernelPackages.digilent-hdmi`](./digilent-hdmi.nix), [`config.boot.kernelPackages.digilent-dynclk`](./digilent-dynclk.nix)
