{ config, lib, pkgs, ... }:
{
  services = {

    gogs = {
      enable = true;
      rootUrl = "https://git.jonasem.com";
      httpPort = 3001;
      domain = "git.jonasem.com";
      database = {
        type = "postgres";
       port = 5432;
      };
    };

    nginx.virtualHosts = {
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
    };
};

}
