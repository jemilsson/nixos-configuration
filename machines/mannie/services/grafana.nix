{ config, lib, pkgs, ... }:
{
  services = {

    grafana = {
     enable = true;
     addr = "127.0.0.1";
     package = pkgs.unstable.grafana;

     database = {
       type = "sqlite3";
     };
    };

    nginx.virtualHosts = {
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
    };
};

nixpkgs.overlays = [
    (self: super: {
      grafana = pkgs.unstable.grafana;
    }
    )
  ];


}
