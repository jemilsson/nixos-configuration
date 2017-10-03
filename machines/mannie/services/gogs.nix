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
        password = "wpA9h83ozkCLE0Peiq98O9uPxmkK6jCG";
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

#nixpkgs.overlays = [
#    (self: super: {
#      gogs = pkgs.unstable.gogs;
#    }
#    )
#  ];

}
