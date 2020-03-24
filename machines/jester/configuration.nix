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

  networking.hostName = "jester";
  system.stateVersion = "19.03";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

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

 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };
 boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

 virtualisation.libvirtd = {
   enable = true;
 };

 boot.extraModprobeConfig = ''
  options snd-intel-dspcfg dsp_driver=0
 '';

}
