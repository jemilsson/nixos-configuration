{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress = "10.5.20.12/24";
  localAddress6 = "2001:470:dc6b::12/64";
  autoStart = true;
  privateNetwork = true;
  #forwardPorts = [
  #  { containerPort = 53; hostPort = 53; protocol = "udp"; }
  #];
}
