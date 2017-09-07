{ config, lib, pkgs, ... }:
let
unstable = import <nixos-unstable> {
  config = config.nixpkgs.config;
};
in
{
  nixpkgs.config.packageOverrides.gogs = unstable.gogs;

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

      extraConfig =
        ''
        [service]
        DISABLE_REGISTRATION = true
        REQUIRE_SIGNIN_VIEW = true

        '';


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
