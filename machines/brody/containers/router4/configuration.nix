{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "mv-wan" = {
      useDHCP = true;
    };

    "eth0" = {
      ipv4 = {
        routes = [
          { address = "10.0.0.0"; prefixLength = 24; via = "10.5.0.1"; }
          { address = "10.5.1.0"; prefixLength = 24; via = "10.5.0.1"; }
          { address = "10.5.2.0"; prefixLength = 24; via = "10.5.0.1"; }
          { address = "10.5.3.0"; prefixLength = 24; via = "10.5.0.1"; }
          { address = "10.5.4.0"; prefixLength = 24; via = "10.5.0.1"; }
        ];
      };
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

    extraCommands = ''
    iptables -I FORWARD -i eth1006-1 -o eth0 -j ACCEPT
    iptables -I FORWARD -i eth1005-1 -o eth0 -j ACCEPT

    iptables -I FORWARD -i eth0 -j ACCEPT

    '';
    #iptables -I FORWARD -i eth0 -o eth1006-1 -s 10.5.0.0/24 -d 10.5.6.0/24 -j ACCEPT
    #iptables -I FORWARD -i eth0 -o eth1006-1 -s 10.0.0.0/24 -d 10.5.6.0/24 -j ACCEPT
    #iptables -I FORWARD -i eth0 -o eth1006-1 -s 10.5.1.0/24 -d 10.5.6.0/24 -j ACCEPT
    #iptables -I FORWARD -i eth0 -o eth1006-1 -s 10.5.2.0/24 -d 10.5.6.0/24 -j ACCEPT
    #'';

  };

  nat = {
    enable = true;
    externalInterface = "mv-wan";
    internalInterfaces = [ "eth1005-1" ];
    forwardPorts = [
      { destination = "10.0.0.180:22"; proto = "tcp"; sourcePort = 22; }
    ];
  };

  wireguard = {
    interfaces = {
      "wg0" = {
        ips = [ "10.5.10.1/24" ];
        privateKeyFile = "/var/wireguard/privakey";
        peers = [
          {
            publicKey = "";
            endpoint = "mannie.jonas.systems:53";
            allowedIPs = [ "10.5.10.0/24" ];
          }
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
