{ config, lib, pkgs, ... }:
{
  services = {
    radicale = {
      enable = true;
      config = pkgs.lib.readFile ./radicale.cfg;
    };

    nginx.virtualHosts = {
      "cal.jonasem.com" = {
        enableSSL = true;
        forceSSL = true;
        enableACME = true;
        locations = {
          "/" = {
            proxyPass = "http://localhost:3000";
            extraConfig = ''
               auth_basic "Restricted";
               auth_basic_user_file /var/db/htpasswd/users;
               '';
          };
        };
      };
    };
};

nixpkgs.overlays = [
    (self: super: {
      radicale = pkgs.unstable.radicale2;
    }
    )
  ];

}
