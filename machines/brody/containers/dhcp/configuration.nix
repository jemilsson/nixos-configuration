{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {};

services = {
  dhcpd4 = {
    enable = false;
    interfaces = [ "lan-1" ];
    extraConfig = ''

      option domain-name-servers 1.1.1.1;

      subnet 10.0.0.0 netmask 255.255.255.0 {
        range 10.0.0.100 10.0.0.200;
        option broadcast-address 10.0.0.255;
        option routers 10.0.0.1;
        option subnet-mask 255.255.255.0;
      }

      subnet 10.0.1.0 netmask 255.255.255.0 {
        range 10.0.1.100 10.0.1.200;
        option broadcast-address 10.0.1.255;
        option routers 10.0.1.1;
        option subnet-mask 255.255.255.0;
      }

      subnet 10.0.5.0 netmask 255.255.255.0 {
        range 10.0.5.100 10.0.5.200;
        option broadcast-address 10.0.5.255;
        option routers 10.0.5.1;
        option subnet-mask 255.255.255.0;
      }


    '';
  };
};



}
