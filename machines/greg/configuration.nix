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
    ../../config/location/sesto01/configuration.nix
    ../../config/services/prometheus/node_exporter.nix
    ../../config/language/english.nix
  ];

  system.stateVersion = "21.05";

  powerManagement = {
    enable = true;
  };

  networking = {
    hostName = "greg";
    useDHCP = false;

    defaultGateway = {
      address = "10.5.20.1";
      interface = "enp2s0";
    };

    #defaultGateway6 = {
    #  address = "2a0e:b107:330::1";
    #  interface = "enp2s0";
    #};

    firewall = {
      allowedTCPPorts = [ 22 8080 8088 19999 1999 ];
      allowedUDPPorts = [ ];
      
    };

    

    interfaces = {
      "enp2s0" = {
        ipv4 = {
          addresses = [
            { address = "10.5.20.4"; prefixLength = 24; }
          ];
        };
        ipv6 = {
          addresses = [
            { address = "2a0e:b107:330::4"; prefixLength = 64; }
          ];
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

  

  #containers = containers;

  virtualisation = {
    oci-containers = {
      containers = {
        "ring-mqtt" = {
          autoStart = true;
          image = "tsightler/ring-mqtt";
          environment = {
            #DEBUG = "*";
          };
          ports = [
              "55123:55123"
          ];
          volumes = [
            "/var/lib/ring-mqtt:/data"
          ];
        };
      };
    };
  };


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
 environment.systemPackages = with pkgs; [
  dnsutils
  deconz

  unstable.pmacct
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
         ExecStart = "${deconz}/bin/deCONZ -platform minimal --http-listen=0.0.0.0";
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
