{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      libinput = {
        enable = true;
        }

      desktopManager = {
        plasma5 = {
          enable = true;
        };
      };

      displayManager = {
        sddm = {
          enable = true;
        };
      };

    };
  };

  environment.systemPackages = with pkgs; [

  ];

  i18n.consoleUseXkbConfig = true;
}
