{ config, lib, pkgs, stdenv, ... }:
let
  containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
in
{
  imports = [
    #<nixos-hardware/lenovo/thinkpad/x1/7th-gen>
    ../../config/laptop_base.nix
    ../../config/services/kvm/kvm.nix
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
   };
   undervolt = {
     enable = false;
   };

   fprintd = {
     enable = true;
   };
 };

 environment.systemPackages = with pkgs; [
  docker
  docker-compose
  (python37Packages.opencv4.override{
    enableGtk2 = true;
    enableFfmpeg=true;
    enableUnfree=true;
    enableCuda=true;
  })
  ffmpeg
  python37Packages.imutils
  python37Packages.scipy
  python37Packages.shapely
  opencl-headers
  labelImg
 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };

 hardware = {
  pulseaudio.extraConfig = ''
    load-module module-alsa-sink   device=hw:0,0 channels=4
    load-module module-alsa-source device=hw:0,6 channels=4
  '';

  opengl = {
    extraPackages = with pkgs; [ intel-ocl ];
  };

 };

 docker-containers = {
   dataturks = {
     image = "klimentij/dataturks";
     ports = [
       "8080:9090"
     ];
   };
 };

 inherit containers;

}
