{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/server_base.nix
  ];

  system.stateVersion = "18.03";

  networking = {
    hostName = "brody";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };
  };


  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

 environment.systemPackages = with pkgs; [
 ];

  services = {

 };
}
