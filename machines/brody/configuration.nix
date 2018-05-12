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
      "lan" = {
        ipv4 = {
          addresses = [
            { address = "10.0.0.1"; prefixLength = 24;}
          ];
        };
      };

    };
    vlans = {
      "lan" = {
        id = 3;
        interface = "enp0s20f0";
      };
    };

    nat = {
      enable = true;
      externalInterface = "enp0s20f0";
      internalInterfaces = [ "lan" ];
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

 environment.systemPackages = with pkgs; [
 ];

  services = {
    dhcpd4 = {
      enable = true;
      interfaces = [ "lan" ];
      extraConfig = ''
        option subnet-mask 255.255.255.0;
        option broadcast-address 10.0.0.255;
        option routers 10.0.0.1;
        option domain-name-servers 1.1.1.1;
        option domain-name "jonas.systems";
        subnet 10.0.0.0 netmask 255.255.255.0 {
          range 10.0.0.100 10.0.0.200;
        }
      '';
    };
 };
}
