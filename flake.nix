{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-22.11";
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
      nixosModules = {
        serverBase = import ./config/server_base.nix;
        desktop_base = import ./config/desktop_base.nix;
        laptopBase = import ./config/laptop_base.nix;
        bareMetal = import ./config/bare_metal.nix;
        #pkgs = pkgs;
      };
      nixosConfigurations = {
        alicia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./machines/alicia/configuration.nix ];
        };
        battlestation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./machines/battlestation/configuration.nix ];
        };
        #brody = nixpkgs.lib.nixosSystem {
        # system = "x86_64-linux";
        #  modules = [ ./machines/brody/configuration.nix ];
        #};
        jester = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./machines/jester/configuration.nix ];
        };
        #lazarus = nixpkgs.lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [ ./machines/lazarus/configuration.nix ];
        #};
        #thor = nixpkgs.lib.nixosSystem {
        #  system = "x86_64-linux";
        #  modules = [ ./machines/thor/configuration.nix ];
        #};
      };
    };
}
