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
    illum.enable = true;
    localtime.enable = true;

    tlp = {
      enable = true;
      extraConfig = ''
      CPU_SCALING_GOVERNOR_ON_AC=performance
      CPU_SCALING_GOVERNOR_ON_BAT=powersave
      '';
    };
  };
  networking.networkmanager.wifi.powersave = true;

  environment.systemPackages = with pkgs; [
    wavemon
    kismet
    powertop
  ];
}
