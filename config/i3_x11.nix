{ config, lib, pkgs, ... }:
let
  taffybar = pkgs.taffybar.override {packages = with pkgs; [ hicolor-icon-theme ];};
in
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

        sessionCommands =''
        systemctl --user import-environment GDK_PIXBUF_MODULE_FILE DBUS_SESSION_BUS_ADDRESS
        '';
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
          wantedBy = [ "graphical-session.target" "taffybar.service" ];
          before = [ "taffybar.service" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.haskellPackages.status-notifier-item}/bin/status-notifier-watcher";

        };
        "taffybar" = {
          enable = true;
          description = "Taffybar";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${taffybar}/bin/taffybar";

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
