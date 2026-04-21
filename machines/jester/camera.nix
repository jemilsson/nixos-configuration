{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel from unstable for xe driver DP-MST fixes (needs 6.21+)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake).
  #
  # Pure libcamera path: kernel ipu6-isys (mainline >=6.10) -> libcamera
  # "simple" pipeline on the raw CSI node -> pipewire-camera (wireplumber
  # libcamera monitor) -> apps. No v4l2-relayd, no icamerasrc, no
  # v4l2loopback. nixpkgs' libcamera lacks an IPU6 IPA, so tuning runs
  # through ipa_soft_simple with uncalibrated.yaml (image quality is
  # mediocre but the stream is stable).
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };
  # hardware.ipu6 defaults this on; we want the pure libcamera path.
  services.v4l2-relayd.instances.ipu6.enable = false;

  environment.systemPackages = with pkgs; [ v4l-utils libcamera ];

  # Camera access requires the video group
  users.users.jonas.extraGroups = [ "video" ];

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
