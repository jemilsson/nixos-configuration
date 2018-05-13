{ config, pkgs, ... }:
let
    router1 = import ./router1/configuration.nix { pkgs = pkgs; config=config; };
in
{
  "router1" = {
    macvlans = [ "enp0s20f0" ];
    config = router1;
}
