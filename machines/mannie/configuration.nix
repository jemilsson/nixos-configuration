{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/server_base.nix
    ../../config/services/nginx/nginx.nix

    ../../config/services/prometheus/prometheus.nix
    ../../config/services/prometheus/nginx_exporter.nix

    services/gogs.nix
    services/synapse.nix
    services/grafana.nix
    services/influxdb.nix
    services/uwsgi.nix
    #services/openvpn.nix
    services/radicale/radicale.nix
    services/helloflask/helloflask.nix

    #test default signed commit
  ];

  networking = {
    hostName = "mannie";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ ];
    };

    defaultGateway6 = {
      address = "2A00:1A28:1510:9::1";
      interface = "ens3";
    };

    interfaces = {
      "ens3" = {
        ip6 = [
          { address = "2A00:1A28:1510:9::3400";
            prefixLength = 64;
          }
        ];
      };

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
    uid = 1002;
    home = "/home/user/";
    extraGroups = [ "wheel" ];
 };

 users.extraUsers.johan = {
    isNormalUser = true;
    uid = 1001;
    home = "/home/johan/";
    extraGroups = [ "wheel" ];
 };

 environment.systemPackages = with pkgs; [
 ];

  services = {

    postgresql = {
     enable = true;
     package = pkgs.postgresql95;
  };

   nginx.virtualHosts = {

         "default.jonasem.com" = {
           default = true;
           extraConfig = "return 444;";
         };


         "emilsson.cloud" = {
           forceSSL = true;
           enableACME = true;
           locations = {
             "/" = {
             extraConfig = ''
                auth_basic "Restricted";
                auth_basic_user_file /var/db/htpasswd/users;
                '';
             root = "/var/www/default";
             index = "index.html";
           };
           };
         };

        "jonasem.com" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
            root = "/var/www/default";
            index = "index.html";
          };
          };
        };

        "ipv6-only.se" = {
          forceSSL = true;
          enableACME = true;
          globalRedirect = "www.ipv6-only.se";
        };

        "www.ipv6-only.se" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              proxyPass = "https://www.ip-only.se";
            };
          };
        };
    };
 };
}
