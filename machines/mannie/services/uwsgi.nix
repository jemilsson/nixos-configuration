{ config, resources, pkgs, ... }:
{
    services = {
      uwsgi = {
        enable = true;
        instance = {
          type = "emperor";
        };
      plugins = [ "python3" ];
      };
    };
}
