{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop_base.nix
  ];

  location.provider = "geoclue2";

  powerManagement = {
    powertop = {
      enable = true;
    };
  };
  services = {
    tlp.enable = true;
    illum.enable = true;
    localtime.enable = true;
  };
  networking.networkmanager.wifi.powersave = true;

  environment.systemPackages = with pkgs; [
    wavemon
    kismet
    powertop
  ];
}
