{ config, lib, pkgs, ... }:

{
  imports = [
    ../config/server_base.nix
  ];

  networking = {
    hostName = "mannie";

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 80 ];
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

 ];

  services = {

    #postgresql = {
     #enable = true;
     #package = pkgs.postgresql96;
  #};

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
      virtualHosts = {
        "grafana.jonasem.com" = {
          locations = {
            "/" = {
              proxyPass = "http://localhost:3000";
            };
          };
        };
      };
   };
 };

}
