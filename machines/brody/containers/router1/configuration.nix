{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  interfaces = {
    "lan" = {
      ipv4 = {
        addresses = [
          { address = "10.0.0.1"; prefixLength = 24;}
        ];
      };
    };
    "wan".useDHCP = true;
  };

  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  nat = {
    enable = true;
    externalInterface = "wan";
    internalInterfaces = [ "lan" ];
  };
};



}
