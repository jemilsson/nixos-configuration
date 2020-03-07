{ config, lib, pkgs, ... }:
{
  services = {
    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      libinput = {
        enable = true;
      };

      xautolock = {
        enable = true;
        locker = "${pkgs.betterlockscreen}/bin/betterlockscreen -l blur";
      };

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
          theme = "breeze";
          autoNumlock = true;

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
      backend = "glx";
      fade = true;
      vSync = true;
      /*
      settings = {
        unredir-if-possible = true;
        no-fading-openclose = true;
        glx-swap-method = "copy";
      };
      */
    };

  };

  programs = {
      sway = {
        enable = true;
      };
  };

  systemd = {
    user = {

      services = {
        "status-notifier-watcher" = {
          enable = true;
          description = "SNI watcher";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.haskellPackages.status-notifier-watcher}/bin/nm-applet --sm-disable --indicator";

        };
      };
    };
  };


  environment.systemPackages = with pkgs; [
    betterlockscreen
    compton
    xorg.xev
    plasma5.sddm-kcm
    i3lock
    xmobar
    taffybar
  ];

  i18n.consoleUseXkbConfig = true;

}
