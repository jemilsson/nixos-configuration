{ config, lib, pkgs, ... }:
let
  unstable = import <nixos-unstable> {};
in
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
    #services/radicale/radicale.nix
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
    extraGroups = [ ];
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
    };
 };
}
