{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/server_base.nix
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

   nginx = {
      enable = true;
      recommendedOptimisation=true;
      recommendedProxySettings=true;
      recommendedTlsSettings = true;
      recommendedGzipSettings = true;
      sslCiphers = "AES256+EECDH:AES256+EDH:!aNULL";
      appendHttpConfig="server_names_hash_bucket_size 128; add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains; preload\" always;";
      sslDhparam = "/var/lib/dhparams/nginx.pem";
      virtualHosts = {
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
 };

 security = {
    dhparams = {
      enable = true;
      params = {
        nginx = 4096;
      };
    };
 };

}
