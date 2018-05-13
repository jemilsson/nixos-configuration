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
  };
  "dhcp" = {
    hostBridge = "br0";
    localAddress = "10.0.0.2/24";
    config = dhcp;
    autoStart = true;
    privateNetwork = true;
  };
}
