{ config, lib, pkgs, ... }:
{
  imports = [
    ../config/x_desktop.nix
  ];
  networking.hostName = "battlestation";

  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };


  services.xserver.videoDrivers = [ "nvidia" ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/user/";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 environment.systemPackages = with pkgs; [
  i3pystatus
  python3
  unstable.teamspeak_client
  #sway
  #way-cooler
  #wayland
  #weston
 ];



}
