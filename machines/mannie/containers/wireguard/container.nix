{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  autoStart = true;
  privateNetwork = true;
  interfaces = [ "wg0" ];

  #forwardPorts = [
  #  { containerPort = 51820; hostPort = 53; protocol = "udp"; }
  #  { containerPort = 51820; hostPort = 1053; protocol = "udp"; }
  #  { containerPort = 51820; hostPort = 1337; protocol = "udp"; }
  #];

}
