{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  autoStart = true;
  privateNetwork = true;
}
