{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
    dhcp = import ./dhcp/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    hostBridge = "br0";
    localAddress = "10.0.0.1/24";
    config = router1;
    autoStart = true;
    privateNetwork = true;

    extraVeths = {
      "ve-wan" = {
        hostBridge = "br1";
        localAddress = "0.0.0.0/0";
      };

    };
  };
  "dhcp" = {
    hostBridge = "br0";
    #hostAddress = "10.0.0.3/24";
    localAddress = "10.0.0.2/24";
    config = dhcp;
    autoStart = true;
    privateNetwork = true;

    bindMounts."/var/lib/dhcp" = {
      isReadOnly = false;
      hostPath = "/var/lib/dhcp";
    };
  };
}
