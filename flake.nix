{
  inputs = {
    nixpkgs = {
      url = "github:NixOS/nixpkgs/nixos-21.11";
    };
  };

  outputs = { self, nixpkgs }: {
    nixosConfigurations = {
      jester = nixpkgs.pkgs.callPackage ./machines/jester/configuration.nix;
    };
  };
}
