{ config, lib, pkgs, ... }:
{
  services = {
    fstrim.enable = true;

    fwupd = {
      enable = true;
      enableTestRemote = true;
      package = pkgs.unstable.fwupd
    };
  };
}
