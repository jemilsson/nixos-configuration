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
      fadeDelta = 3;
      fadeSteps = ["0.25" "0.25"];
      vSync = "opengl-mswc";
      extraOptions = ''
        paint-on-overlay = true;
        sw-opti = true;
        detect-transient = true;
        detect-client-leader = true;
        unredir-if-possible = true;
        xrender-sync = true;

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
