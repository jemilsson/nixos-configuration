{ config, pkgs, ... }:
let
  adblockConfig = builtins.readFile ./adblock.conf;
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    allowedUDPPorts = [ 53 67 68 ];
  };

  defaultGateway = {
    address = "10.0.0.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
  dnsutils
];

services.dnsmasq = {
  enable = true;
  extraConfig = ''
    domain-needed
    bogus-priv

    port = 53

    domain=ynglingagatan.local
    expand-hosts
    local=/ynglingagatan.local/

    listen-address=10.0.0.5

    dhcp-range=lan,10.0.0.100,10.0.0.200
    dhcp-option=lan,3,10.0.0.1
    dhcp-option=lan,6,10.0.0.5
    dhcp-lease-max=50

    server=10.0.0.6

    conf-file=${adblockConfig}

    '';
};


}
