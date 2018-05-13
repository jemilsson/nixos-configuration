{ config, pkgs, ... }:
{
  imports = [
    ../../../../../config/minimum.nix
];

  networking.interfaces."mv-enp0s20f0".useDHCP = true;

}
