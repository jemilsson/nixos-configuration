{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1001";
  localAddress = "10.5.1.4/24";
  autoStart = true;
  privateNetwork = true;
  forwardPorts = [
    { containerPort = 53; hostPort = 53; protocol = "udp"; }
  ];
}
