{ config, pkgs, ... }:
let
peer = "52.59.206.106";
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
        ips = [ "172.16.3.1/24" ];
        # publicKey = "P+VSSgH7+QIvdZBg3l7dDh7o0oZo8Fe5qE7Gk8AwZgI="
        privateKey = "yOtaVE6g93WeMTNhSf/RTACr6rUGkowc/EuxYPvZX2M=";

        peers = [
          {
            endpoint = "${peer}:12913";
            allowedIPs = [ "${peer}/32" ];
            publicKey = "D8AjjmpKa5P703URKB7LuUVEzHfK+QnkjhjFhNpO/mM=";
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
