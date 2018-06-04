{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.6/24";
  autoStart = true;
  privateNetwork = true;
  forwardPorts = [
    { containerPort = 53; hostPort = 53; protocol = "udp"; }
  ];
}
