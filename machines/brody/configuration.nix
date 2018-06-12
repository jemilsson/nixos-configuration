{ config, lib, pkgs, ... }:
let
    containers = import ./containers/containers.nix { pkgs = pkgs; config=config; };
in
{
  imports = [
    ../../config/server_base.nix

    ./networks.nix
  ];

  system.stateVersion = "18.03";

  networking = {
    hostName = "brody";
    useDHCP = false;

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
      allowedUDPPorts = [ ];
    };

    bridges = {
      "br2" = {
        interfaces = [ ];
      };
      "br0" = {
        interfaces = [ "lan-1" ];
      };
    };

    vlans = {
      "management" = {
        id = 5;
        interface = "enp0s20f0";
      };
      "lan-1" = {
        id = 3;
        interface = "enp0s20f0";
      };

      "wan" = {
        id = 2;
        interface = "enp0s20f0";
      };
    };

    interfaces = {

      "br0" = {
        useDHCP = true;
      };
      "lan-1" = {
        useDHCP = false;
      };
      "wan" = {
        useDHCP = false;
      };
    };

  };

  services = {
    lldpd = {
      enable = true;
    };
  };

  containers = containers;

  boot.kernelParams = [ "--- console=ttyS0,115200n8" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

 environment.systemPackages = with pkgs; [
  dnsutils
 ];
}
