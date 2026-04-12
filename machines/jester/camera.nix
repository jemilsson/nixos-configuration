{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel for better driver support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
