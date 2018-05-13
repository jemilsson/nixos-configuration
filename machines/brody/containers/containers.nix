{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    extraVeths = {
      "lan" = {
        hostBridge = "lan-switch-1";
      };
      "wan" = {
        hostBridge = "wan-switch";
      };
    };
    config = router1;
    autoStart = true;
  };
}
