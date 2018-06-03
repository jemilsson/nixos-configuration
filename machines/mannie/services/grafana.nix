{ config, lib, pkgs, ... }:
{
  services = {

    grafana = {
     enable = true;
     addr = "127.0.0.1";
     #package = pkgs.unstable.grafana;
     package = pkgs.grafana;

     database = {
       host = "127.0.0.1:5432";
       name = "grafana";
       password = "ayAV5apytnYzgUsywHpqfsDSLKEAXW7a";
       user = "grafana";
     };

    extraOptions = {
      DATABASE_TYPE = "postgres";
    };

    };

    nginx.virtualHosts = {
      "grafana.jonasem.com" = {
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
      #grafana = pkgs.unstable.grafana;
      grafana = pkgs.grafana;
    }
    )
  ];


}
