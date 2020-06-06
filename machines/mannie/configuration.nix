{ config, lib, pkgs, stdenv, ... }:
let
  #containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  kernel = config.boot.kernelPackages;
in
{
  #inherit containers;
  imports = [
    ../../config/server_base.nix
    #../../config/services/nginx/nginx.nix
    ../../config/language/english.nix

    #../../config/services/prometheus/prometheus.nix
    #../../config/services/prometheus/nginx_exporter.nix

    #services/gogs.nix
    #services/synapse.nix
    #services/grafana.nix
    #services/influxdb.nix
    #services/uwsgi.nix
    #services/openvpn.nix
    #services/radicale/radicale.nix
    #services/helloflask/helloflask.nix

    #test default signed commit
  ];

  system.stateVersion = "20.03";

  boot.extraModulePackages = [ kernel.wireguard ];

  networking = {
    hostName = "mannie";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 53 1053 1054 ];
    };
    /*

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

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.5.254.1/31" ];
          listenPort = 1054;
          privateKeyFile = "/var/wireguard/privatekey";
          allowedIPsAsRoutes = false;
          peers = [
            {
              publicKey = "gzppOIjAm6deU1bie42AICYF8KbQS0JXTF2TpGM8FCs=";
              allowedIPs = [ "0.0.0.0/0" ];
            }
          ];
        };
        wg1 = {
          ips = [ "10.5.10.1/24" ];
          listenPort = 1053;
          privateKeyFile = "/var/wireguard/privatekey";
          allowedIPsAsRoutes = false;
          peers = [
            {
              publicKey = "PglN/x6nY4rruLCqS9u6wWdWCbxcE6448C8+hVqEB30=";
              allowedIPs = [ "10.5.10.3/32" ];
            }
          ];
        };
      };
    };

  */
  };



  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };

 environment.systemPackages = with pkgs; [
  irssi
  screen
  wireguard-tools
 ];

  services = {
   /*
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
        /*
        "ipv6-only.se" = {
          forceSSL = true;
          enableACME = true;
          globalRedirect = "www.ipv6-only.se";
        };


        "www.ipv6-only.se" = {
          forceSSL = true;
          enableACME = true;

          extraConfig = ''
          location / {

              if ($remote_addr ~* "^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$") {
               return 302 https://www.ip-only.se;
             }

              resolver 8.8.8.8;
              proxy_set_header HOST www.ip-only.se;
              proxy_pass https://www.ip-only.se;
          }
          '';

        };
    };
    */
 };
}
