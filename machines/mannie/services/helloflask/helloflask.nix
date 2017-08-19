{ config, resources, pkgs, ... }:
let
    app = import ./default.nix { pkgs = pkgs; };
    pythonPackages = pkgs.python35Packages;
in
{
    environment.systemPackages = [
      pythonPackages.gunicorn

    ];

    #users.extraUsers = {
  #    helloflask = { };
  #  };


    services = {
      nginx.virtualHosts = {
        "helloflask.jonasem.com" = {
          enableSSL = true;
          forceSSL = true;
          enableACME = true;
          locations = {
            "/" = {
              extraConfig = ''
                uwsgi_pass unix://${config.services.uwsgi.instance.vassals.helloflask.socket};
                include ${pkgs.nginx}/conf/uwsgi_params;
                '';
            };
          };
        };
      };


      uwsgi = {
        enable = true;
        instance = {
          type = "emperor";
          vassals = {
            helloflask = {
              pythonPackages = [ app ];
              type = "normal";
              socket = "${config.services.uwsgi.runDir}/flaskhello.sock";
              wsgi-file = "${app}/lib/python3.5/site-packages/helloflask/wsgi.py";
              chmod-socket = "666";
            };
          };

        };


      };



    };

}
