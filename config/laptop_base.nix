{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop_base.nix
  ];

  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  services = {
    tlp.enable = true;
    illum.enable = true;
  };
  networking.networkmanager.wifi.powersave = true;
  programs = {
    nm-applet = {
      enable = true;
    };
  };
}
