{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";
      windowManager.i3.enable = true;

      displayManager = {
        sddm = {
          enable = false;

        };
        lightdm = {
          enable = true;

          greeters.gtk = {
            enable = true;
            theme.name = "Adapta";
          };
        };

        sessionCommands =
          ''
            eval $(gpg-agent --daemon --enable-ssh-support)
            if [ -f "~/.gpg-agent-info" ]; then
              . "~/.gpg-agent-info"
              export GPG_AGENT_INFO
              export SSH_AUTH_SOCK
            fi
          '';
      };

    };


    compton = {
      enable = true;
      fade = true;
      fadeDelta = 3;
      fadeSteps = ["0.25" "0.25"];
      vSync = "opengl";
      extraOptions = ''
        unredir-if-possible = true;
      '';
    };

  };

  environment.systemPackages = with pkgs; [
    compton
    xorg.xev
  ];

  i18n.consoleUseXkbConfig = true;

}
