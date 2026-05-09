{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  outputs =
    { self, nixpkgs }:
    let
      forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
    in
    {
      overlays = {
        xlnx2025_1 = import ./overlay.nix { xlnxVersion = "2025.1"; };
        xlnx2024_1 = import ./overlay.nix { xlnxVersion = "2024.1"; };
      };
      legacyPackages = forAllSystems (system: {
        xlnx2025_1 = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.xlnx2025_1 ];
        };
        xlnx2024_1 = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.xlnx2024_1 ];
        };
      });
      nixosModules.sd-image = import ./sd-image.nix;
    };
}
