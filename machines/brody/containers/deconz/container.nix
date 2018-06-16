{ config, pkgs, stdenv, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  hostBridge = "br1006";
  localAddress = "10.5.6.5/24";
  autoStart = true;
  privateNetwork = true;
}
