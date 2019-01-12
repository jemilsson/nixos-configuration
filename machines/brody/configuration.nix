{ config, lib, pkgs, stdenv, ... }:
let
    containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
    deconz-full = pkgs.callPackage ../../packages/deconz/default.nix {};
    deconz = deconz-full.deCONZ;
    kernel = config.boot.kernelPackages;
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
      allowedTCPPorts = [ 22 8080 8088 19999 1999 ];
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

    wireguard = {
      interfaces = {
        wgdummy = {
          ips = [ "10.5.11.1/24" ];
          privateKeyFile = "/var/wireguard/privakey";
          peers = [
            {
              publicKey = "+ZGgVXQiwTQSzi0oB+1LACUew1nNwuc9TBXkNwNbY1s=";
              endpoint = "mannie.jonas.systems:53";
              allowedIPs = [ "10.5.11.0/24" ];
            }
          ];
        };
      };
    };

  #  vswitches = {
  #    "vs-wan" = {
#
#      };
#    };
#  };

  #virtualisation = {
    #vswitch = {
    #  enable = true;
    #  resetOnStart = true;
    #  extraOvsctlCmds = ''
    #  set-fail-mode &lt;switch_name&gt; secure
    #  set Bridge <switch_name> stp_enable=true
    #
    #      '';
  #  };
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
  boot.extraModulePackages = [ kernel.wireguard ];
  boot.kernelModules = [ "wireguard" ];

 environment.systemPackages = with pkgs; [
  dnsutils
  python2nix
  pypi2nix

 ];

 users.users."deconz" = {
  createHome = true;
  isSystemUser = true;
  group = "dialout";
  home = "/home/deconz";
 };

 systemd.services.deconz = {
       enable = true;
       description = "deconz";
       after = [ "network.target" ];
       wantedBy = [ "multi-user.target" ];
       stopIfChanged = false;
       serviceConfig = {
         ExecStart = "${deconz}/bin/deCONZ -platform minimal --dbg-info=2 --dbg-zcldb=2";
         ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
         Restart = "always";
         RestartSec = "10s";
         StartLimitInterval = "1min";
         #StateDirectory = "/var/lib/deconz";
         User = "deconz";
         #DeviceAllow = "char-ttyUSB rwm";
         #DeviceAllow = "char-usb_device rwm";
         #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
       };
     };
}
