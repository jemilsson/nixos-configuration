{ config, resources, pkgs, ... }:
let
    app = import ./default.nix { pkgs = pkgs; };
in
{
    environment.systemPackages = [
      pkgs.python35Packages.gunicorn
      pkgs.python35Packages.flask

    ];

    systemd.services.helloflask = {
      description = "Hello flask!";
      after = [ "network.target" ];
      environment = { PYTHONUSERBASE = "${app}"; };
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
