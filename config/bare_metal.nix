{ config, lib, pkgs, ... }:
{
  services = {
    fstrim.enable = true;
  };
}
