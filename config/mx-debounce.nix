{ config, lib, pkgs, ... }:
{
  # Load the uinput kernel module (needed for virtual device creation)
  boot.kernelModules = [ "uinput" ];

  systemd.services.mx-debounce = {
    description = "Adaptive debounce daemon for Logitech MX Anywhere 3S";
    after = [ "systemd-udevd.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.mx-debounce}/bin/mx-debounce";
      Restart = "on-failure";
      RestartSec = "2s";
      # Needs root for /dev/input grab and /dev/uinput
    };
    environment = {
      RUST_LOG = "info";
    };
  };
}
