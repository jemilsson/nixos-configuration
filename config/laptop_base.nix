{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop_base.nix
  ];

  powerManagement = {
    enable = true;
    powertop = {
      enable = true;
    };
  };
  services = {
    tlp.enable = true;
    illum.enable = true;
  };
  networking.networkmanager.wifi.powersave = true;
}
