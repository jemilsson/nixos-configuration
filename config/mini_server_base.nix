{ config, lib, pkgs, ... }:

{
  imports = [
    ./mini_base.nix
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
