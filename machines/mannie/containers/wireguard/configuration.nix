{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = true;

    extraCommands = ''
    iptables -I FORWARD -i wg1 -o wg0 -j ACCEPT
    '';

  };


  defaultGateway = { address = "10.5.254.0"; interface = "wg0"; };

  interfaces = {
    wg0 = {

      ipv4 = {

        addresses = [
          { address = "10.5.254.1"; prefixLength = 31; }
        ];
      };
    };
    wg1 = {

      ipv4 = {

        addresses = [
          { address = "10.5.10.1"; prefixLength = 24; }
        ];
      };
    };
  };
};

environment.systemPackages = with pkgs; [
  wireguard-tools
];

services = {};
}
