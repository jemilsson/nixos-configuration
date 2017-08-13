{ config, lib, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
in
{
  users.extraUsers.jonas = {
     createHome = true;
     isNormalUser = true;
     uid = 1000;
     home = "/home/jonas/";
     group = "users";
     isSystemUser = false;
     extraGroups = [ "wheel" "networkmanager" ];
     shell = "/run/current-system/sw/bin/fish";
     openssh.authorizedKeys.keys = [ sshKeys.jonas ];
  };

}
