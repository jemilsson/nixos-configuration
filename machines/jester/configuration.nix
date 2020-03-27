{ config, lib, pkgs, ... }:
let
  dpi = 144;
in
{
  imports = [
    ../../config/laptop_base.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
  ];

  system.stateVersion = "19.03";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.unstable.linuxPackages_latest;
    kernelModules = [ "kvm-intel" ];

    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  networking = {
    hostName = "jester";
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
     package = pkgs.unstable.fprintd-thinkpad;
   };
 };

 environment.systemPackages = with pkgs; [
  virtmanager
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

}
