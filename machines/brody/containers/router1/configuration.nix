{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "wan1" = {
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
    externalInterface = "wan1";
    internalInterfaces = [ "eth0" ];
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
          { addr = "10.0.0.1/24";
            dev = "eth0";
         }
        ];
        virtualRouterId = 0;
      };
    };


  };

};



}
