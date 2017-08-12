{ config, lib, pkgs, ... }:
#ssl_certificate /var/lib/acme/jonasem.com/fullchain.pem;
#ssl_certificate_key /var/lib/acme/jonasem.com/key.pem;
# /var/lib/dhparams/openvpn.pem

let
  openvpn = {
    cert = /var/lib/acme/jonasem.com/fullchain.pem;
    key = /var/lib/acme/jonasem.com/key.pem;
    dh = /var/lib/dhparams/openvpn.pem;
  };

in
{
  security.dhparams.params.openvpn = 4096;

  services = {

    openvpn = {


      servers = {
        server = {
          autoStart = true;

          config = ''
            port 1194
            proto udp
            dev tun
            cert /var/lib/acme/jonasem.com/fullchain.pem
            key /var/lib/acme/jonasem.com/key.pem;
            dh /var/lib/dhparams/openvpn.pem;

            client-cert-not-required

            server 10.8.0.0 255.255.255.0
            keepalive 10 120
            comp-lzo
            max-clients 5
            user nobody
            group nogroup
            persist-key
            persist-tun
            verb 6
            reneg-sec 0
          '';
        };
      };
    };
};

}
