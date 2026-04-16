{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel for better driver support
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake)
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };

  # Camera access requires the video group
  users.users.jonas.extraGroups = [ "video" ];

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
