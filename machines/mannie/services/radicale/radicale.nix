{ config, lib, pkgs, ... }:
{
  services = {
    radicale = {
      enable = true;
      config = pkgs.lib.readFile ./radicale.cfg;
    };
};

}
