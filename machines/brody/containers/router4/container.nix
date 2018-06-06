{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1000";
  localAddress = "10.5.0.4/24";
  autoStart = true;
  privateNetwork = true;

  extraVeths = {
    "wan4" = {
      hostBridge = "br1";
    };
    "eth1006-1" = {
      hostBridge = "br1006";
      localAddress = "10.5.6.1/24";
    };
    "eth1000-4" = {
      hostBridge = "br1000";
      localAddress = "10.5.1.4/24";
    };

  };
}
