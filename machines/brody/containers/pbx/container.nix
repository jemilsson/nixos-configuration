{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress = "10.5.20.13/24";
  localAddress6 = "2001:470:dc6b::13/64";
  autoStart = true;
  privateNetwork = true;
  additionalCapabilities = [ "CAP_SYS_NICE" ];
  #forwardPorts = [
    #{ containerPort = 8123; hostPort = 80; protocol = "tcp"; }
  #];
}
