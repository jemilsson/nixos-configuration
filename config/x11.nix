{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";
      windowManager.i3.enable = true;

      displayManager = {
        ssdm = {
          enable = true;

        };


        lightdm = {
          enable = false;

          greeters.gtk = {
            enable = true;
            theme.name = "Adapta";
          };
        };
      };

    };


    compton = {
      enable = true;
      fade = true;
      fadeDelta = 3;
      fadeSteps = ["0.25" "0.25"];
    };

  };

  environment.systemPackages = with pkgs; [
    compton
    xorg.xev
  ];

  i18n.consoleUseXkbConfig = true;

}
