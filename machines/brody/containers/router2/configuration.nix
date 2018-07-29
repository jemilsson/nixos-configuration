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
    externalInterface = "mv-wan";
    internalInterfaces = [ "eth0" "eth1001-2" "eth1002-3" "eth1004-3" ];
    forwardPorts = [
      { destination = "10.0.0.180:22"; proto = "tcp"; sourcePort = 22; }
    ];
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
        {
          addr = "10.5.0.1/24";
          dev = "eth1000-3";
       }
       {
         addr = "10.5.2.1/24";
         dev = "eth1002-3";
      }
      {
        addr = "10.5.4.1/24";
        dev = "eth1004-3";
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
