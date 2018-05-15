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
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  nat = {
    enable = true;
    externalInterface = "wan2";
    internalInterfaces = [ "eth0" ];
  };
};

services = {
  keepalived = {
    enable = true;
    vrrpInstances = {
      "router_vrrp" = {
        interface = "vrrp2";
        priority = 100;
        unicastPeers = [ "10.250.250.0" ];
        virtualIps = [
          { addr = "10.0.0.1/24";
            brd = "10.0.0.255";
            dev = "eth0";
         }
        ];
        virtualRouterId = 1;
      };
    };


  };

};



}
