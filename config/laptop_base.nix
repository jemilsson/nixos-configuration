{ config, lib, pkgs, ... }:
{
  imports = [
    ./desktop_base.nix
  ];

  location.provider = "geoclue2";

  powerManagement = {
    enable = true;
    # Let TLP handle CPU frequency scaling on laptops
    powertop = {
      enable = false;
    };
  };

  # Laptop suspend/power button configuration
  services.logind = {
    settings = {
      Login = {
        HandlePowerKey = "suspend";
        HandleLidSwitch = "suspend";
        IdleAction = "ignore";
      };
    };
  };
  services = {
    illum.enable = true;
    localtimed.enable = true;
    #automatic-timezoned.enable = true;


    geoclue2 = {
      enable = true;
      /*
        appConfig = {
        "chromium" = {
        isSystem = true;
        isAllowed = true;
        };
        };

        appConfig = {
        "redshift" = {
        isSystem = true;
        isAllowed = true;
        };
        };

        appConfig = {
        "localtimed" = {
        isSystem = true;
        isAllowed = true;
        #desktopID = "998";
        };
        };
      */
    };


    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        USB_AUTOSUSPEND = 0;

      };
    };

    hardware = {
      bolt.enable = true;
    };
  };
  networking.networkmanager.wifi.powersave = true;

  # Auto-open captive portal login page when NetworkManager detects one.
  # NM's connectivity check is enabled in desktop_base.nix.
  # Uses the NM dispatcher (event-driven, gets CONNECTIVITY_STATE in env)
  # and drops privileges to the active graphical user via systemd-run --user.
  networking.networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.writeShellScript "captive-portal-opener" ''
        set -eu
        # NM dispatcher passes action as $2. We only care about connectivity-change.
        [ "''${2:-}" = "connectivity-change" ] || exit 0
        [ "''${CONNECTIVITY_STATE:-}" = "PORTAL" ] || exit 0

        # Find an active graphical user session to send the notification / open browser into.
        user=$(${pkgs.systemd}/bin/loginctl list-sessions --no-legend \
          | ${pkgs.gawk}/bin/awk '$3 != "" && $3 != "root" { print $3; exit }')
        [ -n "''${user:-}" ] || exit 0
        uid=$(${pkgs.coreutils}/bin/id -u "$user")

        run_as_user() {
          ${pkgs.systemd}/bin/systemd-run --user --machine="$user@" --quiet --collect --pipe -- "$@" || true
        }

        # neverssl.com is reliably intercepted by captive portals (no HSTS, plain HTTP).
        run_as_user ${pkgs.libnotify}/bin/notify-send -u critical \
          "Captive portal detected" "Opening login page..."
        run_as_user ${pkgs.xdg-utils}/bin/xdg-open "http://neverssl.com"
      '';
    }
  ];

  environment.systemPackages = with pkgs; [
    wavemon
    #kismet
    powertop
    geoclue2
  ];
}
