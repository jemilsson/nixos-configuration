{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress6 = "2001:470:dc6b::11/64";
  localAddress = "10.5.20.11/24";

  autoStart = true;
  privateNetwork = true;
}
