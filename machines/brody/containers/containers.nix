{ config, pkgs, ... }:
let
    #router2 = import ./router2/configuration.nix { pkgs = pkgs; config=config; };
    #dhcp = import ./dhcp/configuration.nix { pkgs = pkgs; config=config; };
    dnsmasq = import ./dnsmasq/configuration.nix { pkgs = pkgs; config=config; };
    stubby = import ./stubby/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = import ./router1/container.nix { pkgs = pkgs; config=config; };
  "router2" = import ./router2/container.nix { pkgs = pkgs; config=config; };

  "dnsmasq" = {
    hostBridge = "br0";
    localAddress = "10.0.0.5/24";
    config = dnsmasq;
    autoStart = true;
    privateNetwork = true;
    forwardPorts = [
      { containerPort = 53; hostPort = 53; protocol = "udp"; }
    ];
  };
  "stubby" = {
    hostBridge = "br0";
    localAddress = "10.0.0.6/24";
    config = stubby;
    autoStart = true;
    privateNetwork = true;
    forwardPorts = [
      { containerPort = 53; hostPort = 53; protocol = "udp"; }
    ];
  };
}
