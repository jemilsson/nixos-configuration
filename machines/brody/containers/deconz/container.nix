{ config, pkgs, stdenv, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  hostBridge = "br1006";
  localAddress = "10.5.6.5/24";
  autoStart = true;
  privateNetwork = true;
  #additionalCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_KILL" "CAP_SYS_BOOT" "CAP_SYS_TIME"];
  additionalCapabilities = ["CAP_MKNOD"];
  allowedDevices = [
    { modifier = "rwm"; node = "char-ttyUSB"; }
    { modifier = "rwm"; node = "char-usb_device"; }
  ];
  bindMounts = {
    "/dev/ttyUSB0" = {hostPath = "/dev/ttyUSB0"; isReadOnly = false;};
    "/dev/bus/usb/001" = {hostPath = "/dev/bus/usb/001"; isReadOnly = false;};
  };
}
