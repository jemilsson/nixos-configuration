{ config, lib, pkgs, ... }:
let
    containers = import ./containers/containers.nix { pkgs = pkgs; config=config; };
in
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

    vswitches = {
      "wan-switch" = {
        interfaces = [ "wan-1" ];
      };
      "lan-switch-1" = {
        interfaces = [ "lan-1" ];
      };
    };

    interfaces = {
      #"lan-1" = {
      #  ipv4 = {
      #    addresses = [
      #      { address = "10.0.0.2"; prefixLength = 24;}
      #    ];
      #  };
      #};

      #"lan-2" = {
      #  ipv4 = {
      #    addresses = [
      #      { address = "10.0.1.1"; prefixLength = 24;}
      #    ];
      #  };
      #};
      #"wan-2" = {
      #  useDHCP = true;
      #};
      "management" = {
        ipv4 = {
          addresses = [
            { address = "10.0.5.1"; prefixLength = 24;}
            ];
          };
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

      #"lan-2" = {
      #  id = 4;
      #  interface = "enp0s20f0";
      #};

      "wan-1" = {
        id = 2;
        interface = "enp0s20f0";
      };
    };

    #macvlans = {
    #  "wan-2" = {
    #    interface = "enp0s20f0";
    #  };
    #};

    #nat = {
    #  enable = true;
    #  externalInterface = "enp0s20f0";
    #  internalInterfaces = [ "lan-2" ];
    #};
  };

  containers = containers;

  boot.kernelParams = [ "--- console=ttyS0,115200n8" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

 environment.systemPackages = with pkgs; [
 ];

  services = {
    dhcpd4 = {
      enable = false;
      interfaces = [ "lan-1" "lan-2" "management"];
      extraConfig = ''

        option domain-name-servers 1.1.1.1;

        subnet 10.0.0.0 netmask 255.255.255.0 {
          range 10.0.0.100 10.0.0.200;
          option broadcast-address 10.0.0.255;
          option routers 10.0.0.1;
          option subnet-mask 255.255.255.0;
        }

        subnet 10.0.1.0 netmask 255.255.255.0 {
          range 10.0.1.100 10.0.1.200;
          option broadcast-address 10.0.1.255;
          option routers 10.0.1.1;
          option subnet-mask 255.255.255.0;
        }

        subnet 10.0.5.0 netmask 255.255.255.0 {
          range 10.0.5.100 10.0.5.200;
          option broadcast-address 10.0.5.255;
          option routers 10.0.5.1;
          option subnet-mask 255.255.255.0;
        }


      '';
    };
 };
}
