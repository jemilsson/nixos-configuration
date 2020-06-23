{ config, lib, pkgs, stdenv, ... }:
let
  containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  dpi = 144;
in
{
  imports = [
    #<nixos-hardware/lenovo/thinkpad/x1/7th-gen>
    ../../config/laptop_base.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
    ../../config/software/tensorflow.nix
  ];
  system.stateVersion = "19.03";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    kernelModules = [ "kvm-intel" "acpi_call" ];

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "jester";

    bridges = {
      br0 = {
        interfaces = [];
      };
      br1 = {
        interfaces = [];
      };
    };
  };

 services = {
   xserver = {
     videoDrivers = [ "intel" "modesetting" ];
     dpi = dpi;

     /*
     displayManager.sessionCommands = ''
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
        Xft.dpi: ${toString dpi}
       EOF
      '';
    */
   };
   undervolt = {
     enable = false;
   };

   fprintd = {
     enable = true;
     #package = pkgs.unstable.fprintd-thinkpad;
   };
 };

 environment.systemPackages = with pkgs; [
  virtmanager
  docker
  docker-compose
  (python37Packages.opencv4.override{enableGtk2 = true; enableFfmpeg=true;})
  ffmpeg
  python37Packages.imutils
  python37Packages.scipy
  python37Packages.shapely
 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };

 virtualisation = {
  kvmgt = {
    enable = true;
  };
  libvirtd = {
    enable = true;
  };
 };

 hardware.pulseaudio.extraConfig = ''
  load-module module-alsa-sink   device=hw:0,0 channels=4
  load-module module-alsa-source device=hw:0,6 channels=4
'';

 inherit containers;

}
