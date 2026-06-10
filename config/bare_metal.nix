{ config, lib, pkgs, ... }:
{
  services = {
    smartd.enable = true;

    fstrim.enable = true;

    fwupd = {
      enable = true;
      package = pkgs.fwupd;
    };
  };

  # fwupd itself is D-Bus activated, but the package-shipped refresh timer
  # fires hourly and pulls the daemon into RAM ~24x/day. Daily metadata
  # refresh is plenty. This renders as a drop-in over the package unit, and
  # OnCalendar is additive in systemd, so the leading "" resets the shipped
  # hourly schedule instead of stacking a second one. RandomizedDelaySec and
  # Persistent are scalars; the drop-in value simply wins.
  systemd.timers.fwupd-refresh.timerConfig = {
    OnCalendar = [ "" "daily" ];
    RandomizedDelaySec = "1h";
    Persistent = true;
  };

  environment = {
    #disrupts git
    #loginShellInit = "hostname | figlet -f big; fortune -a -s | cowsay";

    systemPackages = with pkgs; [
      ethtool
      wol
      pciutils
    ];
  };
}
