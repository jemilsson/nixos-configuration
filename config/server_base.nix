{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
  ];

  security.sudo.wheelNeedsPassword = false;

  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];

      };

  };
}
