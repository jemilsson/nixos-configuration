{ config, inputs, lib, pkgs, modulesPath, ... }:

let
  # Recompile only the IPA module with a smaller AGC step size (3.3% vs 10%)
  # to eliminate the gain oscillation loop on the OV2740 sensor.
  # WirePlumber's libcamera.so accepts this IPA: both are signed with the
  # same static nixpkgs private key, so signature verification passes.
  libcamera-patched = pkgs.libcamera.overrideAttrs (old: {
    patches = (old.patches or []) ++ [ ./libcamera-agc-step-size.patch ];
  });
in
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

  # Allow WirePlumber's embedded libcamera to open /dev/media0 (char major 243).
  # DevicePolicy=auto in the service unit denies devices not in the cgroup
  # allow-list; char-media is not included by default.
  systemd.user.services.wireplumber.serviceConfig.DeviceAllow = [
    "char-media rw"
  ];

  # Load the patched IPA (smaller AGC step) instead of the default one.
  # LIBCAMERA_IPA_MODULE_PATH is searched before the built-in path, so our
  # ipa_soft_simple.so wins without rebuilding WirePlumber.
  systemd.user.services.wireplumber.environment = {
    LIBCAMERA_IPA_MODULE_PATH = "${libcamera-patched}/lib/libcamera/ipa";
  };

  # Thunderbolt: prevent runtime-suspend which drops DP tunnels
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="thunderbolt", ATTR{power/control}="on"
  '';
}
