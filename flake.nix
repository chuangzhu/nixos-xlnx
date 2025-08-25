{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    overlays = {
      xlnx2025_1 = import ./overlay.nix { xlnxVersion = "2025.1"; };
      xlnx2024_1 = import ./overlay.nix { xlnxVersion = "2024.1"; };
    };
    legacyPackages.aarch64-linux = {
      xlnx2025_1 = import nixpkgs { system = "aarch64-linux"; overlays = [ self.overlays.xlnx2025_1 ]; };
      xlnx2024_1 = import nixpkgs { system = "aarch64-linux"; overlays = [ self.overlays.xlnx2024_1 ]; };
    };
    nixosModules.sd-image = import ./sd-image.nix;
  };
}
