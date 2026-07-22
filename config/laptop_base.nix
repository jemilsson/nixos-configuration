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
        # intel_pstate runs in active mode: the "performance" governor pins
        # min=max P-state and forces EPP=performance, defeating HWP's
        # fine-grained frequency management. "powersave" is Intel's
        # recommended active-mode governor; HWP then honors the EPP hint.
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        # HWP transiently raises EPP under load: snappier compile/LSP bursts
        # on AC with no battery cost.
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        USB_AUTOSUSPEND = 0;

      };
    };

    hardware = {
      bolt.enable = true;
    };
  };
  # false = NM stops re-asserting powersave at every (re)connect, letting
  # TLP's per-power-source defaults govern instead (WIFI_PWR_ON_AC=off for
  # lower SSH RTT jitter to the remote builder, WIFI_PWR_ON_BAT=on unchanged).
  networking.networkmanager.wifi.powersave = false;

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

        run_as_user ${pkgs.libnotify}/bin/notify-send -u critical \
          "Captive portal detected" "Opening login page..."
        ${if config.programs.captive-browser.enable then ''
          # captive-browser: isolated Chromium on the Wi-Fi interface using the
          # portal's own DHCP DNS, immune to VPN routes and DNS overrides.
          run_as_user /run/current-system/sw/bin/captive-browser
        '' else ''
          # neverssl.com is reliably intercepted by captive portals (no HSTS, plain HTTP).
          run_as_user ${pkgs.xdg-utils}/bin/xdg-open "http://neverssl.com"
        ''}
      '';
    }
  ];

  # Sticky critical notification when any battery drops below 5% while discharging.
  # Polls every 60s; 5% → 0% takes minutes, so polling is sufficient and simpler
  # than wiring into UPower D-Bus signals. Runs as a user unit so notify-send
  # reaches the session bus directly without machinectl hops.
  systemd.user.services.low-battery-notify = {
    description = "Notify when battery is critically low";
    serviceConfig.Type = "oneshot";
    script = ''
      set -eu
      shopt -s nullglob
      for bat in /sys/class/power_supply/BAT*; do
        status=$(cat "$bat/status" 2>/dev/null || echo Unknown)
        cap=$(cat "$bat/capacity" 2>/dev/null || echo 100)
        if [ "$status" = "Discharging" ] && [ "$cap" -lt 5 ]; then
          exec ${pkgs.libnotify}/bin/notify-send \
            -u critical -t 0 \
            -a Battery \
            -h string:x-canonical-private-synchronous:low-battery \
            -h string:synchronous:low-battery \
            "Battery critically low" "$cap% remaining, plug in now."
        fi
      done
    '';
  };

  systemd.user.timers.low-battery-notify = {
    description = "Periodic low-battery check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "1min";
      OnUnitActiveSec = "60s";
      AccuracySec = "10s";
      Persistent = true;
    };
  };

  environment.systemPackages = with pkgs; [
    wavemon
    #kismet
    powertop
    geoclue2
    libnotify
  ];
}
