{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel from unstable for xe driver DP-MST fixes (needs 6.21+)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake).
  # kernel ipu6-isys -> libcamera "simple" pipeline -> wireplumber -> apps.
  boot.extraModulePackages = with config.boot.kernelPackages; [ ipu6-drivers ];
  hardware.firmware = with pkgs; [ ipu6-camera-bins ivsc-firmware ];

  environment.systemPackages = with pkgs; [ libcamera ];

  users.users.jonas.extraGroups = [ "video" ];

  # Open IPU6 media pipeline nodes to the video group so wireplumber/libcamera
  # can enumerate them. Numbered 100- to run after 99-local.rules.
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "ipu6-camera-access-rules";
      destination = "/lib/udev/rules.d/100-ipu6-camera-access.rules";
      text = ''
        SUBSYSTEM=="intel-ipu6-psys", MODE="0660", GROUP="video"
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
