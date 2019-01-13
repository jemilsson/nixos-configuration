{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  defaultGateway = { address = "10.5.10.1"; interface = "wg0"; };

  interfaces = {
    wg0 = {

      ipv4 = {

        addresses = [
          { address = "10.5.10.2"; prefixLength = 24; }
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
