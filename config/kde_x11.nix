{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      xkb = {
        layout = "se";
        options = "eurosign:e";
      };
    };

    libinput = {
      enable = true;
    };

    desktopManager = {
      plasma6 = {
        enable = true;
      };
    };

    displayManager = {
      sddm = {
        enable = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [

  ];

  console.useXkbConfig = true;
}
