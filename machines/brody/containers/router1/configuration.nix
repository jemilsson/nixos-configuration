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

    "eth1000-2" = {
      ipv4 = {
        routes = [
          { address = "10.5.6.0"; prefixLength = 24; via = "10.5.0.4"; }
          { address = "10.5.5.0"; prefixLength = 24; via = "10.5.0.4"; }
        ];
      };
    };
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ ];
    allowedUDPPorts = [ ];

    extraCommands = ''
    iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.5.6.4 -j MARK --set-xmark 0x1/0xffffffff
    iptables -t nat -A nixos-nat-pre -i eth0 -p udp --dport 53 ! -d 10.5.6.4 -j DNAT --to 10.5.6.4
    iptables -t nat -A nixos-nat-post -o eth0 -p udp --dport 53 -m mark --mark 0x1 -j MASQUERADE

    iptables -I FORWARD -i eth0 -o eth1000-2 -j ACCEPT

    iptables -I FORWARD -i eth1000-2 -j ACCEPT

    iptables -A nixos-fw -i eth1000-2 -p udp -m udp --dport 67:68 -j nixos-fw-accept

    '';
    #iptables -I FORWARD -i eth1000-2 -o eth0 -s 10.5.0.0/24 -d 10.0.0.0/24 -j ACCEPT
    #iptables -I FORWARD -i eth1000-2 -o eth0 -s 10.5.6.0/24 -d 10.0.0.0/24 -j ACCEPT
    #iptables -I FORWARD -i eth1000-2 -o eth0 -s 10.5.6.0/24 -d 10.5.1.0/24 -j ACCEPT

    #iptables -I FORWARD -i eth1000-2 -o eth1002-2 -s 10.5.6.0/24 -d 10.5.2.0/24 -j ACCEPT
    #'';
  };

  nat = {
    enable = true;
    externalInterface = "mv-wan";
    internalInterfaces = [ "eth0" "eth1001-1" "eth1002-2" "eth1004-2" ];
  };
};

services = {
  keepalived = {
    enable = true;
    vrrpInstances = {
      "router_vrrp" = {
        state = "MASTER";
        interface = "vrrp1";
        priority = 150;
        unicastPeers = [ "10.250.250.2" ];
        virtualIps = [
          {
            addr = "10.0.0.1/24";
            dev = "eth0";
         }
         {
           addr = "10.5.1.1/24";
           dev = "eth1001-1";
        }
        {
          addr = "10.5.0.1/24";
          dev = "eth1000-2";
       }
       {
         addr = "10.5.2.1/24";
         dev = "eth1002-2";
      }
      {
        addr = "10.5.4.1/24";
        dev = "eth1004-2";
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

systemd.services.dhcrelay = {
      enable = true;
      description = "dhcrelay";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${pkgs.dhcp}/bin/dhcrelay -4 -d -a -i eth1000-2 -i eth1001-1 -i eth1002-2  -i eth0 -i eth1004-2 10.5.6.4";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };



}
