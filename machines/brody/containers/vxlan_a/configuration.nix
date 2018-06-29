{ config, pkgs, ... }:
let
  dnsServerAddress = "10.5.6.4";
in
{
  imports = [
    ../../../../config/minimum.nix
];



networking = {

  useNetworkd = true;

  firewall = {
    allowedUDPPorts = [ 4789 ];
  };

  #defaultGateway = {
  #  address = "10.5.6.1";
  #  interface = "eth0";
  #};
};

systemd.network = {
  enable = true;
  netdevs."vx01" = {
    enable = true;

    netdevConfig = {
      Name = "vx01";
      Kind = "vxlan";
    };

    vxlanConfig = {
        Id = "1";
        Group = "10.5.6.9";
    };
  };
};

environment.systemPackages = with pkgs; [
];

services = {
  };
}
