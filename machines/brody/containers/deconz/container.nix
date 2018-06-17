{ config, pkgs, stdenv, ... }:
{
  config = import ./configuration.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  hostBridge = "br1006";
  localAddress = "10.5.6.5/24";
  autoStart = true;
  privateNetwork = true;
  #additionalCapabilities = ["CAP_NET_BIND_SERVICE" "CAP_KILL" "CAP_SYS_BOOT" "CAP_SYS_TIME"];
  additionalCapabilities = ["all"];
  allowedDevices = [
    { modifier = "rwm"; node = "/dev/ttyUSB0:/dev/ttyUSB0"; }
  ];
}
