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
          "/radicale/" = {
            proxyPass = "http://localhost:5232/";
            extraConfig = ''
               proxy_set_header  X-Script-Name /radicale/;
               proxy_set_header     X-Forwarded-For $proxy_add_x_forwarded_for;
               proxy_set_header     X-Remote-User $remote_user;
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
