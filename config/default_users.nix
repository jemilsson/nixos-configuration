{ config, lib, pkgs, ... }:
let
  sshKeys = import ./ssh-keys.nix;
  # When the syna SSH module is enabled it owns authorized_keys for
  # privileged users and rejects foreign contributions. Hand off the keys
  # to it on those hosts; otherwise keep the legacy plain-list behaviour.
  synaOwnsKeys = config.services.syna.ssh.enable or false;
in
{
  users.users.jonas = {
    createHome = true;
    isNormalUser = true;
    home = "/home/jonas";
    group = "users";
    uid = 1000;
    isSystemUser = false;
    extraGroups = [ "wheel" "networkmanager" "libvirtd" "docker" "plugdev" "tss" "tty" "dialout" "lxd" "wireshark" ];
    shell = pkgs.zsh;
    openssh.authorizedKeys.keys = lib.mkIf (!synaOwnsKeys) sshKeys.jonas;
  };

  users.groups.plugdev = { };

}
