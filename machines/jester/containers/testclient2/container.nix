{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1";
  autoStart = true;
  privateNetwork = true;
}
