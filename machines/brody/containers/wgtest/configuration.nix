{ config, pkgs, ... }:
let
a = "asd";
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = true;
  };
  nameservers = [ "10.5.6.4" ];

  defaultGateway = {
    address = "10.5.5.1";
    interface = "eth0";
  };

  wireguard = {
    interfaces = {
      wg0 = {
        ips = [ "172.16.3.1" ];
        privateKey = "yAnz5TF+lXXJte14tji3zlMNq+hd2rYUIgJBgB3fBmk=";

        peers = [
          {
            endpoint = "54.93.48.21:12913";
            allowedIPs = [ "54.93.48.21/32" ];
            publicKey = "xTIBA5rboUvnH4htodjb6e697QjLERt1NAB4mZqp8Dg";

          }
        ];
      };


    };
  };
};



environment.systemPackages = with pkgs; [
  wireguard
];

}
