{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    extraVeths = {
      "lan" = {
        hostBridge = "lan-bridge-1";
      };
      "wan" = {
        hostBridge = "wan-bridge";
      };
    };
    config = router1;
    autoStart = true;
  };
}
