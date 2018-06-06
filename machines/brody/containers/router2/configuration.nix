{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "wan2" = {
      useDHCP = true;
    };
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    extraCommands = ''
    iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.0.0.5 -j MARK --set-xmark 0x1/0xffffffff
    iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.0.0.5 -j DNAT --to 10.0.0.5
    iptables -t nat -A nixos-nat-post -o eth0 -p udp --dport 53 -m mark --mark 0x1 -j MASQUERADE
    '';
  };

  nat = {
    enable = true;
    externalInterface = "wan2";
    internalInterfaces = [ "eth0" "eth1001-2" ];
  };
};

services = {
  keepalived = {
    enable = true;
    vrrpInstances = {
      "router_vrrp" = {
        state = "BACKUP";
        interface = "vrrp2";
        priority = 100;
        unicastPeers = [ "10.250.250.1" ];
        virtualIps = [
          { addr = "10.0.0.1/24";
            dev = "eth0";
         }
         {
           addr = "10.5.1.1/24";
           dev = "eth1001-2";
        }
        ];
        virtualRouterId = 1;
        extraConfig = ''
          advert_int 0.1
        '';
      };
    };


  };

};



}
