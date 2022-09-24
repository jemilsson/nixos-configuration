{ config, lib, pkgs, ... }:
let
  /*
    taffybar = pkgs.unstable.haskellPackages.ghcWithPackages (self: [
    self.taffybar
    pkgs.hicolor-icon-theme
    pkgs.paper-icon-theme
    pkgs.gnome2.gnome_icon_theme
    pkgs.gnome3.adwaita-icon-theme
    pkgs.pantheon.elementary-icon-theme
    pkgs.gtk3
    pkgs.bash
    ]);
  */
  #taffybar = pkgs.unstable-small.taffybar;

in
{
  sound.mediaKeys.enable = true;


  services = {

    actkbd = {
      enable = true;
    };

    system-config-printer.enable = true;

    xserver = {
      enable = true;
      layout = "se";
      xkbOptions = "eurosign:e";

      libinput = {
        enable = true;
      };

      windowManager = {
        i3 = {
          enable = false;
        };
        xmonad = {
          enable = false;
          extraPackages = haskellPackages: [
            haskellPackages.xmonad-contrib
            haskellPackages.xmonad-extras
            #haskellPackages.taffybar
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
          #theme = "breeze";
          autoNumlock = true;

        };
        lightdm = {
          enable = false;

          greeters.gtk = {
            enable = true;
            #theme.name = "Adapta";
          };
        };

        sessionCommands = ''
          systemctl --user import-environment XDG_DATA_DIRS DBUS_SESSION_BUS_ADDRESS NO_AT_BRIDGE
        '';
      };

    };

    blueman.enable = true;


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
      extraSessionCommands = ''
        export WLR_DRM_NO_MODIFIERS=1
      '';
    };

    xwayland.enable = true;

    system-config-printer.enable = true;
  };

  systemd = {
    user = {

      services = {

        kanshi = {
          enable = true;
          description = "kanshi";

          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];

          environment = {
            XDG_CURRENT_DESKTOP = "sway";
            XDG_SESSION_TYPE = "wayland";
            XDG_RUNTIME_DIR = "/run/user/1000";
            WAYLAND_DISPLAY = "wayland-1";
            WLR_DRM_NO_MODIFIERS = "1";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.kanshi}/bin/kanshi";
            Restart = "always";
          };

        };
        /*
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
        */
        "pasystray" = {
          enable = true;
          description = "Pulse audio systray";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.pasystray}/bin/pasystray";
        };


        "nm-applet" = {
          enable = true;
          description = "Network manager applet";
          wantedBy = [ "graphical-session.target" ];
          wants = [ "taffybar.service" ];
          after = [ "status-notifier-watcher.service" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --sm-disable --indicator";

        };
        /*
          "blueman-applet" = {
          enable = true;
          description = "Bluetooth manager applet";
          wantedBy = [ "graphical-session.target" ];
          wants = [ "taffybar.service" ];
          after = ["status-notifier-watcher.service" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.blueman}/bin/blueman-applet";
          };
        */

      };
    };
  };


  environment.systemPackages = with pkgs; [
    #betterlockscreen
    #compton
    xorg.xev
    #plasma5.sddm-kcm
    #i3lock
    #xmobar
    #taffybar
    #i3lock-fancy
    pkgs.networkmanagerapplet


    xdg-desktop-portal
    xdg-desktop-portal-wlr
  ];


  #environment.sessionVariables = {
  #  MOZ_ENABLE_WAYLAND = "1";
  #  XDG_CURRENT_DESKTOP = "sway";
  #  XDG_SESSION_TYPE = "wayland";
  ##};

  console.useXkbConfig = true;

}
