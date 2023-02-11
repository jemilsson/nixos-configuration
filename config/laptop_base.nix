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
    localtimed.enable = true;

    geoclue2 = {
      enable = true;

      appConfig = {
        "chromium" = {
          isSystem = true;
          isAllowed = true;
        };
      };

      appConfig = {
        "redshift" = {
          isSystem = true;
          isAllowed = true;
        };
      };

      appConfig = {
        "localtime" = {
          isSystem = true;
          isAllowed = true;
          desktopID = "998";
        };
      };
    };


    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        USB_AUTOSUSPEND = 0;

      };
    };

    hardware = {
      bolt.enable = true;
    };
  };
  networking.networkmanager.wifi.powersave = true;

  environment.systemPackages = with pkgs; [
    wavemon
    #kismet
    powertop
    geoclue2
  ];
}
