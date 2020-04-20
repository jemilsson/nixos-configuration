{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress = "10.5.20.9/24";
  localAddress6 = "2001:470:dc6b::9/64";
  autoStart = true;
  privateNetwork = true;
  interfaces = [ "enp0s20f1" ];
  additionalCapabilities = [ "CAP_NET_ADMIN" "CAP_NET_RAW" ];
  #forwardPorts = [
    #{ containerPort = 8123; hostPort = 80; protocol = "tcp"; }
  #];
}
