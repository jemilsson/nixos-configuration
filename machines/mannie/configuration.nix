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

    interfaces = {
      ens3 = {
        ipv6 = {
          addresses = [
            { address = "2001:19f0:5001:1062::1"; prefixLength = 64; }
          ];
        };
      };
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 443 ];
      allowedUDPPorts = [ 53 1053 1054 ];
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.5.254.1/31" ];
          listenPort = 1054;
          privateKeyFile = "/var/wireguard/privatekey";
          allowedIPsAsRoutes = true;
          peers = [
            {
              publicKey = "gzppOIjAm6deU1bie42AICYF8KbQS0JXTF2TpGM8FCs=";
              allowedIPs = [ "10.5.254.0/32" ];
            }
          ];
        };
      };
    };

    localCommands = ''
      ip link set dev wg0 mtu 1542
      ip link delete gretap1
      ip link add gretap1 type gretap local 10.5.254.1 remote 10.5.254.0
      ip link set gretap1 up mtu 1500
      ip addr add 10.5.254.3 peer 10.5.254.2 dev gretap1
      ip addr add 2a0e:b107:330:fffe::2/64 dev gretap1
    '';

    /*
0

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

  */
  };

  boot = {
    kernelModules = [
      "fou"
    ];
    loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/vda";
    };


  };

 environment.systemPackages = with pkgs; [
  irssi
  screen
  wireguard-tools
  bird2
 ];

  services = {
    bird2 = {
      enable = true;
      config = (builtins.readFile ./bird/bird.conf);
    };
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
