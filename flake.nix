{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-23.05";
    };
    nixpkgs-unstable = {
      url = "github:NixOS/nixpkgs/nixos-unstable";
    };
    bambu-studio = {
      url = "github:zhaofengli/nixpkgs/bambu-studio";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, bambu-studio }:
    let
      system = "x86_64-linux";
      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
        bambu-studio = import bambu-studio {
          inherit system;
          config.allowUnfree = true;
        };
      };
    in
    {
      nixosModules = {
        serverBase = import ./config/server_base.nix;
        desktopBase = import ./config/desktop_base.nix;
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
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            ./machines/jester/configuration.nix
          ];

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
