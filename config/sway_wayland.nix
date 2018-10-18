{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      windowManager = {
      };




      displayManager = {
        sddm = {
          enable = true;
          theme = "breeze";

        };
        session = [
          {
            manage = "window";
            name = "sway";
            start = ''
              {pkgs.sway/bin/sway} &
              waitPID=$!
            '';
          }
        ];
      };
    };
  };
  programs = {
    sway = {
      enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    sway
    wayland

  ];

  i18n.consoleUseXkbConfig = true;

}
