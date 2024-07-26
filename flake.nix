{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }: {
    overlays.default = import ./overlay.nix;
    legacyPackages.aarch64-linux = import nixpkgs {
      system = "aarch64-linux";
      overlays = [ self.overlays.default ];
    };
    devShells.aarch64-linux.default = with self.legacyPackages.aarch64-linux; mkShell {
      nativeBuildInputs = [ ];
      buildInputs = with gst_all_1; [ gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly gst-omx-zynqultrascaleplus ];
    };
    nixosModules.sd-image = import ./sd-image.nix;
  };
}
