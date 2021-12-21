{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-21.11";
    };
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = import nixpkgs {
        config.allowUnfree = true;
        overlays = [
          #(import inputs.emacs-overlay)
        ];
      };
    in
    {
      nixosConfigurations = {
        jester = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./machines/jester/configuration.nix ];
        };

      };
    };
}
