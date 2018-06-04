{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.3/24";
  autoStart = true;
  privateNetwork = true;

  extraVeths = {
    "wan2" = {
      hostBridge = "br1";
    };
    "vrrp2" = {
      hostBridge = "br2";
      localAddress = "10.250.250.2/24";
    };

  };
}
