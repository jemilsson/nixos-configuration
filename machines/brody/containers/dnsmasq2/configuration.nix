{ config, pkgs, ... }:
let
  adblockConfig =  builtins.readFile ./adblock.conf;
  adblockConfigFile = builtins.toFile "adblock.conf" adblockConfig;

  dnsServerAddress = "10.5.6.4";
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
    address = "10.5.6.1";
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

    listen-address=${dnsServerAddress}

    server=10.0.0.6

    conf-file=${adblockConfigFile}

    dhcp-range=lan,10.0.0.100,10.0.0.200
    dhcp-option=lan,3,10.0.0.1
    dhcp-option=lan,6,${dnsServerAddress}
    dhcp-lease-max=50

    dhcp-range=lan,10.5.1.100,10.5.1.200
    dhcp-option=lan,3,10.5.1.1
    dhcp-option=lan,6,${dnsServerAddress}
    dhcp-lease-max=50

    dhcp-range=lan,10.5.2.100,10.5.2.200
    dhcp-option=lan,3,10.5.2.1
    dhcp-option=lan,6,${dnsServerAddress}
    dhcp-lease-max=50

    dhcp-range=lan,10.5.3.100,10.5.3.200
    dhcp-option=lan,3,10.5.3.1
    dhcp-option=lan,6,${dnsServerAddress}
    dhcp-lease-max=50

    dhcp-range=lan,10.5.4.100,10.5.4.200
    dhcp-option=lan,3,10.5.4.1
    dhcp-option=lan,6,${dnsServerAddress}
    dhcp-lease-max=50



    '';
};


}
