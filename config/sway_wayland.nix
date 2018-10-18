{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      windowManager = {
      };

      programs = {
        sway = {
          enable = true;
        };
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

  environment.systemPackages = with pkgs; [

  ];

  i18n.consoleUseXkbConfig = true;

}
