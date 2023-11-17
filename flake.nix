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
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    #sops-nix = {
    #  url = "github:Mic92/sops-nix";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    /*
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    */
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, bambu-studio, hyprland, sops-nix}: # , agenix, agenix-rekey }:
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

      pkgs = import nixpkgs {
        config.allowUnfree = true;
        inherit system;
        overlays = 
          [  ];
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
        battlestation = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            #agenix.nixosModules.default
            #agenix-rekey.nixosModules.default
            ./machines/battlestation/configuration.nix 
            ];
        };
        
        jester = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            #agenix.nixosModules.default
            #agenix-rekey.nixosModules.default
            ./machines/jester/configuration.nix
          ];

        };


        alicia = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ({ config, pkgs, ... }: { nixpkgs.overlays = [ overlay-unstable ]; })
            #agenix.nixosModules.default
            #agenix-rekey.nixosModules.default
            ./machines/alicia/configuration.nix
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

      apps = {
        #"x86_64-linux" = agenix-rekey.defineApps self pkgs self.nixosConfigurations;
      };
    };
}
