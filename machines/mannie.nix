{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in
{
  imports = [
    ../config/server_base.nix
    ../config/services/nginx/nginx.nix
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
    unstable.gogs
 ];

  services = {

    postgresql = {
     enable = true;
     package = pkgs.postgresql;
  };

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

   matrix-synapse = {
     enable = true;
     no_tls = true;
     public_baseurl = "https://emilsson.chat/";
     server_name = "emilsson.chat";
     database_type = "psycopg2";
     database_args = {
        user = "synapse";
        password = "";
        database = "synapse";
        host = "127.0.0.1";
        cp_min = "5";
        cp_max = "10";
     };
     listeners = [
      {
        bind_address = "127.0.0.1";
        port = 8448;
        tls = false;
        type = "http";
        x_forwarded = true;
        resources = [
          { compress = false;
            names = [ "client" "webclient"];
          }
        ];
      }
     ];


   };

   gogs = {
     enable = true;
     rootUrl = "https://git.jonasem.com";
     httpPort = 3001;
     database = {
       type = "postgres";
      port = 5432;
     };
   };

   nginx.virtualHosts = {

         "default.jonasem.com" = {
           default = true;
           extraConfig = "return 444;";
         };


         "emilsson.cloud" = {
           enableSSL = true;
           forceSSL = true;
           enableACME = true;
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
          locations = {
            "/" = {
            root = "/var/www/default";
            index = "index.html";
          };
          };
        };

        "emilsson.chat" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:8448";
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

        "git.jonasem.com" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "http://localhost:3001";
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
