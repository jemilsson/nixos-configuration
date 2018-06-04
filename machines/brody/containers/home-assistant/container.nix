{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.7/24";
  autoStart = true;
  privateNetwork = true;
  forwardPorts = [
    { containerPort = 80; hostPort = 8123; protocol = "udp"; }
  ];
}
