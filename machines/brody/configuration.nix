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

    interfaces = {

    };
    vlans = {
      "lan" = {
        id = 3;
        interface = "enp0s20f0";
      };
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

 environment.systemPackages = with pkgs; [
 ];

  services = {

 };
}
