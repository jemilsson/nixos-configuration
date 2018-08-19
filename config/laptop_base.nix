{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop_base.nix
  ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
    powertop = {
      enable = true;
    };
  };
  tlp.enable = true;
  networking.networkmanager.wifi.powersave = true;
}
