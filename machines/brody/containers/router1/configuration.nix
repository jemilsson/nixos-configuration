{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  interfaces."mv-enp0s20f0".useDHCP = true;

  firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    allowedUDPPorts = [ ];
  };

  nat = {
    enable = true;
    externalInterface = "mv-enp0s20f0";
    internalInterfaces = [ "lan-1" ];
  };
};



}
