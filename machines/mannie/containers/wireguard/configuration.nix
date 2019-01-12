{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    wg0 = {
      ipv4 = {
        routes = [
          { address = "0.0.0.0"; prefixLength = 0; via = "10.5.10.1"; }
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