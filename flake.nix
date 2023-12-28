{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    overlays.default = import ./overlay.nix;
    legacyPackages.aarch64-linux = import nixpkgs {
      system = "aarch64-linux";
      overlays = [
        (final: prev: {
          pkgsCross = prev.pkgsCross // {
            pmu = import nixpkgs {
              crossSystem = with nixpkgs.lib.systems.parse; {
                # TODO: file a bug to Nixpkgs
                # Nixpkgs parses this to config microblazeel-none-elf, GCC: Configuration microblazeel-none-elf not supported
                system = "microblazeel-none";
                # If set to microblazeel-xilinx-none-elf, GCC: Kernel `none' not known to work with OS `elf'.
                config = "microblazeel-xilinx-elf";
                # With the config above and without parsed.vendor below, Nixpkgs: Unknown vendor: xilinx
                parsed = {
                  _type = "system";
                  cpu = cpuTypes.microblaze;
                  vendor = { _type = "vendor"; name = "xilinx"; };
                  kernel = kernels.none;
                  abi = abis.elf;
                };
                libc = "newlib";
              };
              localSystem.system = "aarch64-linux";
              overlays = [ self.overlays.default ]; # zynqmp-pmufw
            };
          };
        })
        self.overlays.default
      ];
    };
    devShells.aarch64-linux.default = with self.legacyPackages.aarch64-linux; mkShell {
      nativeBuildInputs = [ ];
      buildInputs = with gst_all_1; [ gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-omx-zynqultrascaleplus ];
    };
    nixosModules.sd-image = import ./sd-image.nix;
  };
}
