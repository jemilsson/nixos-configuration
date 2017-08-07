{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in
{
  imports = [
    ../config/server_base.nix
    ../config/services/nginx.nix
  ];

  networking = {
    hostName = "mannie";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ ];
    };

  };


  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/user/";
    extraGroups = [ "wheel" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 users.extraUsers.johan = {
    isNormalUser = true;
    uid = 1001;
    home = "/home/johan/";
    extraGroups = [ "wheel" ];
    shell = "/run/current-system/sw/bin/fish";
 };

 environment.systemPackages = with pkgs; [
    python35Packages.websocket_client
    python35Packages.influxdb
 ];

 environment.systemPackages = with unstable; [
    gogs
 ];

  services = {

    #postgresql = {
     #enable = true;
     #package = pkgs.postgresql96;
  #};

  radicale = {
    enable = true;
    config = pkgs.lib.readFile ../config/service_configs/radicale.cfg;
  };

   influxdb = {
     enable = true;
   };

   grafana = {
    enable = true;
    addr = "127.0.0.1";

    database = {
      type = "sqlite3";
    };
   };

   nginx.virtualHosts = {
         "emilsson.cloud" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
           default = true;
           locations = {
             "/" = {
             root = "/var/www/default";
             index = "index.html";
           };
           };
         };

         "emilsson.cloud" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
           default = true;
           locations = {
             "/" = {
             root = "/var/www/default";
             index = "index.html";
           };
           };
         };

        "jonasem.com" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          default = true;
          locations = {
            "/" = {
            root = "/var/www/default";
            index = "index.html";
          };
          };
        };

        "grafana.jonasem.com" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:3000";
            };
          };
        };
        "influxdb.jonasem.com" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8086";
            };
          };
        };
    };
 };
}
