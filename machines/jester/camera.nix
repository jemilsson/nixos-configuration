{ config, inputs, lib, pkgs, modulesPath, ... }:

{
  # Use latest kernel from unstable for xe driver DP-MST fixes (needs 6.21+)
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  # Intel IPU6 MIPI camera (OV2740 sensor, Raptor Lake)
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };

  # Fix nixpkgs bug: icamerasrc-ipu6ep uses the default ipu6-camera-hal (Tiger
  # Lake) instead of ipu6ep-camera-hal (Alder/Raptor Lake). Override gst_all_1
  # so icamerasrc-ipu6ep links against the correct HAL.
  nixpkgs.overlays = [
    (final: prev: {
      gst_all_1 = prev.gst_all_1 // {
        icamerasrc-ipu6ep = prev.gst_all_1.icamerasrc-ipu6ep.override {
          ipu6-camera-hal = final.ipu6ep-camera-hal;
        };
      };
    })
  ];

  # Camera access requires the video group
  users.users.jonas.extraGroups = [ "video" ];

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
