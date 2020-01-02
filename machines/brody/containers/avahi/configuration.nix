{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  defaultGateway = { address = "10.5.24.1";};

  };

services = {
  avahi = {
    enable = true;
    reflector = true;
    nssmdns = true;
    ipv6 = true;
    ipv4 = false;
    interfaces = [ "eth0" "eth1024-1" ];
  };
};
    environment.systemPackages = with pkgs; [

    ];



}
