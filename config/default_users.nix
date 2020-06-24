{ config, lib, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
in
{
  users.users.jonas = {
     createHome = true;
     isNormalUser = true;
     home = "/home/jonas";
     group = "users";
     uid = 1000;
     isSystemUser = false;
     extraGroups = [ "wheel" "networkmanager" "libvirtd" "docker" ];
     shell = "/run/current-system/sw/bin/zsh";
     openssh.authorizedKeys.keys = sshKeys.jonas;
  };

}
