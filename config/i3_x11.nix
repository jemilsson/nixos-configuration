{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      windowManager = {
        i3 = {
          enable = true;
        };
        xmonad = {
          enable = true;
          extraPackages = haskellPackages: [
            haskellPackages.xmonad-contrib
            haskellPackages.xmonad-extras
            haskellPackages.taffybar
          ];
        };


      };

      displayManager = {
        gdm = {
          enable = false;
          wayland = true;
        };
        sddm = {
          enable = true;

        };
        lightdm = {
          enable = false;

          greeters.gtk = {
            enable = true;
            theme.name = "Adapta";
          };
        };

        #sessionCommands =
        #  ''
        #    eval $(gpg-agent --daemon --enable-ssh-support)
        #    if [ -f "~/.gpg-agent-info" ]; then
        #      . "~/.gpg-agent-info"
        #      export GPG_AGENT_INFO
        #      export SSH_AUTH_SOCK
        #    fi
        #  '';
      };

    };


    compton = {
      enable = true;
      backend = "xrender";
      fade = true;
      fadeDelta = 8;
      fadeSteps = ["0.03" "0.03"];
      vSync = "opengl-mswc";
      extraOptions = ''
        detect-transient = true;
        detect-client-leader = true;
        unredir-if-possible = true;
        xrender-sync = true;
        no-fading-openclose = true;

      '';
    };

  };

  environment.systemPackages = with pkgs; [
    compton
    xorg.xev
    plasma5.sddm-kcm
  ];

  i18n.consoleUseXkbConfig = true;

}