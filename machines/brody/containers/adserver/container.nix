{ config, pkgs, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; };
  hostBridge = "br0";
  localAddress = "10.0.0.8/24";
  autoStart = true;
  privateNetwork = true;
  bindMounts = [
    { /var/certificates = { hostPath = "/var/certificates"; isReadOnly = true; }; }
  ];
  #forwardPorts = [
    #{ containerPort = 8123; hostPort = 80; protocol = "tcp"; }
  #];
}
