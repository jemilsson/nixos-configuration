{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking.defaultGateway.interface = "eth0";

environment.systemPackages = with pkgs; [
  stubby
  dnsutils
];

systemd.services."stubby" = {
  enable = true;
  script = "stubby";
};


}
