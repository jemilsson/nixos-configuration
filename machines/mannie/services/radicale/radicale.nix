{ config, lib, pkgs, ... }:
{
  services = {
    radicale = {
      enable = true;
      config = pkgs.lib.readFile ./radicale.cfg;
    };
};

nixpkgs.overlays = [
    (self: super: {
      radicale = pkgs.unstable.radicale2;
    }
    )
  ];

}
