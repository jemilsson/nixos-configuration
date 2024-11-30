{ config, lib, pkgs, ... }:
let

in
{
  #sound.mediaKeys.enable = true;


  services = {

    actkbd = {
      enable = true;
    };

    greetd = {
      enable = true;
      restart = true;
    };

    libinput = {
      enable = true;
    };

    system-config-printer.enable = true;

    xserver = {
      enable = true;
      xkb = {
        options = "eurosign:e";
        layout = "se";
      };

      windowManager = {
        hypr = {
          enable = true;
        };
      };

      displayManager = {
          sessionCommands = ''
          systemctl --user import-environment XDG_DATA_DIRS DBUS_SESSION_BUS_ADDRESS NO_AT_BRIDGE
        '';
        };

        
      };

    blueman.enable = true;

  };

  programs = {
    regreet = {
      enable = true;
      #settings = ./regreet.toml;
    };
    xwayland.enable = true;

    hyprland = {
      enable = true;
      xwayland = {
        enable = true;
      };
    };

    nm-applet = {
      enable = true;
      indicator = true;
    };


    hyprlock.enable = true;
    waybar.enable = true;

    system-config-printer.enable = true;

    
  };

  systemd = {
    user = {

      services = {

        kanshi = {
          enable = true;
          description = "kanshi";

          partOf = [ "graphical-session.target" ];
          requires = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          wantedBy = [ "graphical-session.target" ];

          environment = {
            XDG_CURRENT_DESKTOP = "sway";
            XDG_SESSION_TYPE = "wayland";
            XDG_RUNTIME_DIR = "/run/user/1000";
            WAYLAND_DISPLAY = "wayland-1";
            WLR_DRM_NO_MODIFIERS = "1";
          };
          serviceConfig = {
            Type = "simple";
            ExecStart = "${pkgs.unstable.kanshi}/bin/kanshi";
            Restart = "always";
          };

        };
        
        "pasystray" = {
          enable = true;
          description = "Pulse audio systray";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          serviceConfig.ExecStart = "${pkgs.pasystray}/bin/pasystray";
        };
      };
    };
  };


  environment.systemPackages = with pkgs; [
    xorg.xev

    pkgs.networkmanagerapplet

    hyprland
    hyprlock
    brightnessctl

    mako

    xdg-desktop-portal
    xdg-desktop-portal-wlr
  ];


  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.overrideAttrs (oldAttrs: {
        mesonFlags = oldAttrs.mesonFlags ++ [ "-Dexperimental=true" ];
      });
    })
  ];


  environment.sessionVariables = {
  #  NIXOS_OZONE_WL = "1";
  #  MOZ_ENABLE_WAYLAND = "1";
  #  XDG_CURRENT_DESKTOP = "sway";
  #  XDG_SESSION_TYPE = "wayland";
  };
  console.useXkbConfig = true;
}
