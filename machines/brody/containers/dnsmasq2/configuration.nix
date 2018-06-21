{ config, pkgs, ... }:
let
  adblockConfig =  builtins.readFile ./adblock.conf;
  adblockConfigFile = builtins.toFile "adblock.conf" adblockConfig;

  localHostsConfig =  builtins.readFile ./adblock.conf;
  localHostsConfigFile = builtins.toFile "adblock.conf" adblockConfig;

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

services = {

  dnsmasq = {
    enable = true;
    extraConfig = ''
      domain-needed
      bogus-priv
      expand-hosts

      port = 53

      domain=ynglingagatan.local

      listen-address=${dnsServerAddress}

      server=10.5.1.4

      conf-file=${adblockConfigFile}
      conf-file${localHostsConfigFile}

      dhcp-lease-max=50

      dhcp-range=oldlan,10.0.0.100,10.0.0.200,255.255.255.0
      dhcp-option=oldlan,3,10.0.0.1
      dhcp-option=oldlan,6,${dnsServerAddress}

      dhcp-range=lan,10.5.1.100,10.5.1.200,255.255.255.0
      dhcp-option=lan,3,10.5.1.1
      dhcp-option=lan,6,${dnsServerAddress}

      dhcp-range=wlan,10.5.2.100,10.5.2.200,255.255.255.0
      dhcp-option=wlan,3,10.5.2.1
      dhcp-option=wlan,6,${dnsServerAddress}

      dhcp-range=guestlan,10.5.3.100,10.5.3.200,255.255.255.0
      dhcp-option=guestlan,3,10.5.3.1
      dhcp-option=guestlan,6,${dnsServerAddress}

      dhcp-range=medialan,10.5.4.100,10.5.4.200,255.255.255.0
      dhcp-option=medialan,3,10.5.4.1
      dhcp-option=medialan,6,${dnsServerAddress}
      '';
    };
  };
}
