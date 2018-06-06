{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "wan4" = {
      useDHCP = true;
    };
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    #extraCommands = ''
    #iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.0.0.5 -j MARK --set-xmark 0x1/0xffffffff
    #iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.0.0.5 -j DNAT --to 10.0.0.5
    #iptables -t nat -A nixos-nat-post -o eth0 -p udp --dport 53 -m mark --mark 0x1 -j MASQUERADE
    #'';
  };

  nat = {
    enable = true;
    externalInterface = "wan4";
    internalInterfaces = [ ];
  };
};

services = {};



}
