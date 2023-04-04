{ config, lib, pkgs, ... }:

{
  imports = [
    ./base.nix
    ./services/prometheus/node_exporter.nix
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
