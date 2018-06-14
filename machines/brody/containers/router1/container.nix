{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.2/24";
  autoStart = true;
  privateNetwork = true;

  macvlans = [ "wan" ];

  extraVeths = {
    #"wan1" = {
    #  hostBridge = "br1";
    #};
    "vrrp1" = {
      hostBridge = "br2";
      localAddress = "10.250.250.1/24";
    };
    "eth1001-1" = {
      hostBridge = "br1001";
      localAddress = "10.5.1.2/24";
    };
    "eth1000-2" = {
      hostBridge = "br1000";
      localAddress = "10.5.0.2/24";
    };
    "eth1002-2" = {
      hostBridge = "br1002";
      localAddress = "10.5.2.2/24";
    };
    "eth1004-2" = {
      hostBridge = "br1004";
      localAddress = "10.5.4.2/24";
    };

  };
}
