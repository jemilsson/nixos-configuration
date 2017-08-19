{ config, resources, pkgs, ... }:
let
    app = import ./default.nix { pkgs = pkgs; };
    pythonPackages = python35Packages;
in
{
    environment.systemPackages = [
      pythonPackages.gunicorn
      pythonPackages.flask

    ];

    systemd.services.helloflask = {
      description = "Hello flask!";
      after = [ "network.target" ];
      environment = {
        PYTHONUSERBASE = "${app}";
        PYTHONPATH = "${app}/lib/python3.5/site-packages";
      };
      serviceConfig = {
        ExecStart = "${app}/bin/gunicorn helloflask.wsgi";
        Restart = "always";
        User = "helloflask";
      };
    };

    users.extraUsers = {
      helloflask = { };
    };

    services.nginx.virtualHosts = {
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

    services.openssh.enable = true;
}
