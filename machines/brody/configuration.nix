{ config, lib, pkgs, stdenv, ... }:
let
    containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
    deconz-full = pkgs.callPackage ../../packages/deconz/default.nix {};
    deconz = deconz-full.deCONZ;
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
      allowedTCPPorts = [ 22 8080 19999 1999 ];
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
    netdata = {
      enable = true;
    };
  };

  containers = containers;

  boot.kernelParams = [ "--- console=ttyS0,115200n8" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

 environment.systemPackages = with pkgs; [
  dnsutils
  python2nix

 ];

 systemd.services.deconz = {
       enable = true;
       description = "deconz";
       after = [ "network.target" ];
       wantedBy = [ "multi-user.target" ];
       stopIfChanged = false;
       serviceConfig = {
         ExecStart = "${deconz}/bin/deCONZ -platform minimal --dbg-info=2";
         ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
         Restart = "always";
         RestartSec = "10s";
         StartLimitInterval = "1min";
         #DeviceAllow = "char-ttyUSB rwm";
         #DeviceAllow = "char-usb_device rwm";
         #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
       };
     };
}
