{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br1020";
  localAddress = "10.5.20.10/24";
  localAddress6 = "2a0e:b107:330::10/64";
  autoStart = true;
  privateNetwork = true;
  #forwardPorts = [
    #{ containerPort = 8123; hostPort = 80; protocol = "tcp"; }
  #];
}
