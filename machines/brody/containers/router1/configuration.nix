{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  
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
