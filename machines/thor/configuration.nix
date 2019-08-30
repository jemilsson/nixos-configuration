{ config, lib, pkgs, ... }:

{
  imports = [
    ../../config/laptop_base.nix
    ../../config/i3_x11.nix
    ../../config/kde_x11.nix
    ../../emilsson.nix
  ];

  system.stateVersion = "19.03";

  networking.hostName = "thor";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };


  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

 services = {
   xserver = {
     videoDrivers = [ "intel" ];
   };
 };

 environment.systemPackages = with pkgs; [

 ];

}
