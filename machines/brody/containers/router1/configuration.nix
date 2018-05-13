{ config, pkgs, ... }:
{

  networking.interfaces."mv-enp0s20f0".useDHCP = true;

}
