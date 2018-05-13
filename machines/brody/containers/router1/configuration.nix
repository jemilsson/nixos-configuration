{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "lan-1" = {
      ipv4 = {
        addresses = [
          { address = "10.0.0.2"; prefixLength = 24;}
        ];
      };
    };
    "mv-enp0s20f0".useDHCP = true;
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  nat = {
    enable = true;
    externalInterface = "mv-enp0s20f0";
    internalInterfaces = [ "mv-lan-1" ];
  };
};



}
