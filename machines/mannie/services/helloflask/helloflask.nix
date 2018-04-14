{ config, resources, pkgs, ... }:
let
    app = import ./default.nix { pkgs = pkgs; };
in
{
    services = {
      nginx.virtualHosts."helloflask.jonasem.com" = {
          forceSSL = true;
          enableACME = true;
          locations = {
            "/static/" = {
              alias = "${app}/lib/python3.6/site-packages/helloflask/static/";
            };
            "/" = {
              extraConfig = ''
                uwsgi_pass unix://${config.services.uwsgi.instance.vassals.helloflask.socket};
                include ${pkgs.nginx}/conf/uwsgi_params;
                '';
            };
          };
      };

      uwsgi.instance.vassals.helloflask = {
              pythonPackages = self: with self; [ app ];
              type = "normal";
              socket = "${config.services.uwsgi.runDir}/flaskhello.sock";
              wsgi-file = "${app}/lib/python3.6/site-packages/helloflask/wsgi.py";
              chmod-socket = "666";
            };

    };
}
