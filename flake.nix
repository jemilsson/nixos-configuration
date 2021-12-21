{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-21.11";
    };
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          #(import inputs.emacs-overlay)
        ];
      };
    in
    {
      nixosConfigurations = {
        jester = pkgs.callPackage ./machines/jester/configuration.nix;
      };
    };

}
