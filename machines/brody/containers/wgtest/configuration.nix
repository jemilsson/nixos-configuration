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
        # publicKey = "P+VSSgH7+QIvdZBg3l7dDh7o0oZo8Fe5qE7Gk8AwZgI="
        privateKey = "yOtaVE6g93WeMTNhSf/RTACr6rUGkowc/EuxYPvZX2M=";

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
