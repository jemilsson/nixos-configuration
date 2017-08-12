{ config, lib, pkgs, ... }:
{
  services = {

    influxdb = {
      enable = true;
    };

    nginx.virtualHosts = {
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
