{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
    dhcp = import ./dhcp/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    extraVeths = {
      "lan-router1" = {
        hostBridge = "lan-bridge-1";
      };
      "wan-router1" = {
        hostBridge = "wan-bridge";
      };
    };
    config = router1;
    autoStart = true;
  };
  "dhcp" = {
    extraVeths = {
      "lan-dhcp" = {
        hostBridge = "lan-bridge-1";
      };
    };
    config = dhcp;
    autoStart = true;
  };
}
