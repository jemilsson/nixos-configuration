{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/server_base.nix
  ];
  networking.hostName = "mannie";

  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/user/";
    extraGroups = [ "wheel" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 environment.systemPackages = with pkgs; [

 ];

 services = {
   postgresql = {
     enable = true;
     package = pkgs.postgresql96;
   };

 };

}
