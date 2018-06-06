{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {

  defaultGateway = {
    address = "10.5.6.1";
    interface = "eth0";
  };

};



services = {
  dhcpd4 = {
    enable = true;
    interfaces = [ "eth0" ];
    extraConfig = ''

      option domain-name-servers 10.0.0.5;

      subnet 10.0.0.0 netmask 255.255.255.0 {
        range 10.0.0.100 10.0.0.200;
        option broadcast-address 10.0.0.255;
        option routers 10.0.0.1;
        option subnet-mask 255.255.255.0;
      }

      subnet 10.5.1.0 netmask 255.255.255.0 {
        range 10.5.1.100 10.5.1.200;
        option broadcast-address 10.5.1.255;
        option routers 10.5.1.1;
        option subnet-mask 255.255.255.0;
      }
    '';
  };
};


}
