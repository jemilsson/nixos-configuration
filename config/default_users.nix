{ config, lib, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
in
{
  users.users.jonas = {
     createHome = true;
     isNormalUser = true;
     home = "/home/jonas/";
     group = "users";
     isSystemUser = false;
     extraGroups = [ "wheel" "networkmanager" ];
     shell = "/run/current-system/sw/bin/zsh";
     #openssh.authorizedKeys.keys = [ sshKeys.jonas ];
  };

}
