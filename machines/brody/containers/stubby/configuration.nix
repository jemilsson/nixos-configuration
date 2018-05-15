{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {};

environment.systemPackages = with pkgs; [
  stubby
  dnsutils
];

systemd.services."stubby" = {
  enable = true;
  script = "stubby";
};


}
