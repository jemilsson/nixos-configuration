{ config, lib, pkgs, ... }:
{
  services = {
    fstrim.enable = true;
    fwupd.enable = true;
  };
}
