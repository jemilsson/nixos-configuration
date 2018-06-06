{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1006";
  localAddress = "10.5.6.4/24";
  autoStart = true;
  privateNetwork = true;
}
