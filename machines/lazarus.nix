{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/x_desktop.nix
  ];
  networking.hostName = "lazarus";

  #boot.loader.grub.device = "/dev/sda";

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/user/";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 environment.systemPackages = with pkgs; [
 ];

}
