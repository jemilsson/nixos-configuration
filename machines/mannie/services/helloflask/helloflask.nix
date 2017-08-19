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
              proxyPass = "http://localhost:8000";
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
              type = "normal";
              socket = "${config.services.uwsgi.runDir}/flaskhello.sock";
              wsgi-file = "${app}/lib/python3.5/site-packages/helloflask/wsgi.py";
            };
          };

        };


      };



    };

}
