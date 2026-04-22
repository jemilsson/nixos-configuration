{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel from unstable for xe driver DP-MST fixes (needs 6.21+)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake).
  # kernel ipu6-isys -> libcamera "simple" pipeline -> wireplumber -> apps.
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };
  # hardware.ipu6 enables v4l2-relayd by default; disable it.
  services.v4l2-relayd.instances.ipu6.enable = false;

  environment.systemPackages = with pkgs; [ libcamera ];

  # Camera access requires the video group
  users.users.jonas.extraGroups = [ "video" ];

  # hardware.ipu6 locks /dev/media* and /dev/video* to root:root 0600.
  # This file (100-) runs after 99-local.rules and re-opens them to the
  # video group so wireplumber/libcamera can enumerate the pipeline.
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "ipu6-camera-access-rules";
      destination = "/lib/udev/rules.d/100-ipu6-camera-access.rules";
      text = ''
        SUBSYSTEM=="media", DRIVERS=="intel-ipu6", GROUP="video", MODE="0660", TAG+="uaccess"
        SUBSYSTEM=="video4linux", DRIVERS=="intel-ipu6", GROUP="video", MODE="0660", TAG+="uaccess"
      '';
    })
  ];

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
