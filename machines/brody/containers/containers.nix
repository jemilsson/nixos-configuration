{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
    router2 = import ./router2/configuration.nix { pkgs = pkgs; config=config; };
    dhcp = import ./dhcp/configuration.nix { pkgs = pkgs; config=config; };
    stubby = import ./stubby/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    hostBridge = "br0";
    localAddress = "10.0.0.2/24";
    config = router1;
    autoStart = true;
    privateNetwork = true;

    extraVeths = {
      "wan1" = {
        hostBridge = "br1";
      };
      "vrrp1" = {
        hostBridge = "br2";
        localAddress = "10.250.250.1/24";
      };

    };
  };
  "router2" = {
    hostBridge = "br0";
    localAddress = "10.0.0.3/24";
    config = router2;
    autoStart = true;
    privateNetwork = true;

    extraVeths = {
      "wan2" = {
        hostBridge = "br1";
      };
      "vrrp2" = {
        hostBridge = "br2";
        localAddress = "10.250.250.2/24";
      };

    };
  };
  "dhcp" = {
    hostBridge = "br0";
    #hostAddress = "10.0.0.3/24";
    localAddress = "10.0.0.4/24";
    config = dhcp;
    autoStart = true;
    privateNetwork = true;

    bindMounts."/var/lib/dhcp" = {
      isReadOnly = false;
      hostPath = "/var/lib/dhcp";
    };
  };
  "stubby" = {
    hostBridge = "br0";
    localAddress = "10.0.0.5/24";
    config = stubby;
    autoStart = true;
    privateNetwork = true;
  };
}
