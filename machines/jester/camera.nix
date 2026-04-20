{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel from unstable for xe driver DP-MST fixes (needs 6.21+)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake).
  # Apps access the camera via PipeWire's libcamera integration, so the
  # v4l2-relayd / v4l2loopback compatibility shim isn't needed. This also
  # keeps the camera LED off until something actually requests the camera.
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };
  services.v4l2-relayd.instances.ipu6.enable = lib.mkForce false;

  # Camera access requires the video group
  users.users.jonas.extraGroups = [ "video" ];

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
