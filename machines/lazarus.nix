{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/x_desktop.nix
  ];
  networking.hostName = "lazarus";

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  #boot.loader.grub.device = "/dev/sda";

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/jonas/";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 services.xserver.desktopManager.gnome3.enable = true;

 environment.systemPackages = with pkgs; [
 ];

}
