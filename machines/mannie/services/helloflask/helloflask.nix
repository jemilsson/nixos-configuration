{ config, resources, pkgs, ... }:
let
    app = import ./default.nix { pkgs = pkgs; };
in
{
    environment.systemPackages = [ pkgs.python35Packages.gunicorn ];

    systemd.services.helloflask = {
      description = "Hello flask!";
      after = [ "network.target" ];
      environment = { PYTHONUSERBASE = "${app}"; };
      serviceConfig = {
        ExecStart = "${pkgs.python35Packages.gunicorn}/bin/gunicorn helloflask.wsgi";
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
            proxyPass = "http://localhost:3001";
          };
        };
      };
    };

    services.openssh.enable = true;
}
