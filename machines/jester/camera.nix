{ config, inputs, lib, pkgs, modulesPath, ... }:

let
  ivsc-firmware = with pkgs;
    stdenv.mkDerivation rec {
      pname = "ivsc-firmware";
      version = "main";

      src = pkgs.fetchFromGitHub {
        owner = "intel";
        repo = "ivsc-firmware";
        rev = "10c214fea5560060d387fbd2fb8a1af329cb6232";
        sha256 = "sha256-kEoA0yeGXuuB+jlMIhNm+SBljH+Ru7zt3PzGb+EPBPw=";

      };

      installPhase = ''
        mkdir -p $out/lib/firmware/vsc/soc_a1_prod

        cp firmware/ivsc_pkg_ovti01a0_0.bin $out/lib/firmware/vsc/soc_a1_prod/ivsc_pkg_ovti01a0_0_a1_prod.bin
        cp firmware/ivsc_skucfg_ovti01a0_0_1.bin $out/lib/firmware/vsc/soc_a1_prod/ivsc_skucfg_ovti01a0_0_1_a1_prod.bin
        cp firmware/ivsc_fw.bin $out/lib/firmware/vsc/soc_a1_prod/ivsc_fw_a1_prod.bin
      '';
    };
in
{
  # Load also non-free firmwares in the kernel
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  #sound.enable = true; # This starts alsactl store, this is needed not to run alsactl init everytime we reboot (otherwise we do not have a working microphone)pipewire
  # for sake of ipu6-camera-bins
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    # https://discourse.nixos.org/t/v4l2loopback-cannot-find-module/26301/5
    v4l-utils
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod" "i915" ];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [ "kvm-intel" ];
 
  boot.extraModulePackages = [];

  # https://discourse.nixos.org/t/i915-driver-has-bug-for-iris-xe-graphics/25006/10
  # resolved: i915 0000:00:02.0: [drm] Selective fetch area calculation failed in pipe A
  boot.kernelParams = [
    "i915.enable_psr=0"
    # Disable auto-exposure oscillation by forcing manual mode
    "ov2740.disable_auto_exposure=1"
    "intel_ipu6_isys.auto_exposure=0"
  ];

  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  boot.extraModprobeConfig = ''
    options v4l2loopback nr_devices=0
    options ov2740 disable_auto_exposure=1 exposure=300 gain=300
    options intel_ipu6_isys auto_exposure=0 disable_auto_ae=1
    options intel_ipu6_psys disable_auto_exposure=1
  '';
  # Tracking Issue: Intel MIPI/IPU6 webcam-support
  # https://github.com/NixOS/nixpkgs/issues/225743#issuecomment-1849613797
  # Infrastructure Processing Unit
  # Re-enabling external drivers to fix auto-exposure oscillation
  hardware.ipu6 = {
    enable = true;
    platform = "ipu6ep";
  };

  # Use stable kernel with external IPU6 drivers
  boot.kernelPackages = pkgs.linuxPackages.extend ( self: super: {
    ipu6-drivers = super.ipu6-drivers.overrideAttrs (
        final: previous: rec {
          src = builtins.fetchGit {
            url = "https://github.com/intel/ipu6-drivers.git";
            ref = "master";
            rev = "b4ba63df5922150ec14ef7f202b3589896e0301a"; # Known working commit updated for kernel 6.12+
          };
          patches = [
            "${src}/patches/0001-v6.10-IPU6-headers-used-by-PSYS.patch"
          ];
        }
    );
  } );

  hardware.firmware = [
    ivsc-firmware
  ];

  # These rules must be understood like a script executed sequentially for
  # all devices. Instead of creating conditions, they use the old fashion
  # goto mechanism to skip some rules tu apply using goto and label
  # The first parts of each line is like a conditiong and the second part
  # describes what to run in that case.
  # To see the properties of a device, just run something like
  # udevadm info -q all -a /dev/video9
  services.udev.extraRules = ''
    SUBSYSTEM!="video4linux", GOTO="hide_cam_end"
    #ATTR{name}=="Intel MIPI Camera", GOTO="hide_cam_end"
    ATTR{name}!="Dummy video device (0x0000)", GOTO="hide_cam_end"
    ACTION=="add", RUN+="${pkgs.coreutils}/bin/mkdir -p /dev/not-for-user"
    ACTION=="add", RUN+="${pkgs.coreutils}/bin/mv -f $env{DEVNAME} /dev/not-for-user/"
    # Since we skip these rules for the mipi, we do not need to link it back to /dev
    # ACTION=="add", ATTR{name}!="Intel MIPI Camera", RUN+="${pkgs.coreutils}/bin/ln -fs $name /dev/not-for-user/$env{ID_SERIAL}"

    ACTION=="remove", RUN+="${pkgs.coreutils}/bin/rm -f /dev/not-for-user/$name"
    ACTION=="remove", RUN+="${pkgs.coreutils}/bin/rm -f /dev/not-for-user/$env{ID_SERIAL}"

    LABEL="hide_cam_end"
  '';

  # environment.etc.camera.source = "${ipu6-camera-hal}/share/defaults/etc/camera";

  # Service to set fixed camera exposure values at boot to prevent oscillation
  systemd.services.fix-camera-exposure = {
    description = "Set fixed camera exposure values to prevent auto-exposure oscillation";
    after = [ "multi-user.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Wait for camera device to be available
      ${pkgs.coreutils}/bin/sleep 10
      
      # Set fixed exposure and gain values multiple times to override auto-exposure
      for i in {1..5}; do
        if [ -e /dev/v4l-subdev4 ]; then
          ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=exposure=300 || true
          ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=analogue_gain=300 || true
          ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=digital_gain=1024 || true
          ${pkgs.coreutils}/bin/sleep 1
        fi
      done
    '';
  };

  # Timer to continuously enforce camera settings to prevent oscillation
  systemd.timers.enforce-camera-settings = {
    description = "Continuously enforce camera exposure settings";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30s";
      OnUnitActiveSec = "10s";
      Unit = "enforce-camera-settings.service";
    };
  };

  systemd.services.enforce-camera-settings = {
    description = "Enforce fixed camera exposure settings";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      if [ -e /dev/v4l-subdev4 ]; then
        # Force fixed values to prevent oscillation
        ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=exposure=300 || true
        ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=analogue_gain=300 || true
        ${pkgs.v4l-utils}/bin/v4l2-ctl -d /dev/v4l-subdev4 --set-ctrl=digital_gain=1024 || true
      fi
    '';
  };

}