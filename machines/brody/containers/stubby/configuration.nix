{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking.defaultGateway = {
  address = "10.0.0.1";
  interface = "eth0";
};
environment.systemPackages = with pkgs; [
  stubby
  dnsutils
];

systemd.services."stubby" = {
  enable = true;
  script = "stubby";
};


}
