{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.2/24";
  autoStart = true;
  privateNetwork = true;

  extraVeths = {
    "wan1" = {
      hostBridge = "br1";
    };
    "vrrp1" = {
      hostBridge = "br2";
      localAddress = "10.250.250.1/24";
    };

  };
}
