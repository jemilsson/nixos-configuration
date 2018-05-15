{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "wan" = {
      useDHCP = true;
    };
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  nat = {
    enable = true;
    externalInterface = "wan";
    internalInterfaces = [ "eth0" ];
  };
};

services = {
  keepalived = {
    enable = true;
    vrrpInstances = {
      "router_vrrp" = {
        interface = "vrrp";
        priority = 150;
        unicastPeers = [ "10.255.255.1" ];
        virtualIps = [
          { addr = "10.0.0.1/24";
            brd = "10.0.0.255";
            dev = "eth0";
         }
        ];
        virtualRouterId = 0;
      };
    };


  };

};



}
