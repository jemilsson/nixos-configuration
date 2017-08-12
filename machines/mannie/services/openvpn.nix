{ config, lib, pkgs, ... }:
#ssl_certificate /var/lib/acme/jonasem.com/fullchain.pem;
#ssl_certificate_key /var/lib/acme/jonasem.com/key.pem;
# /var/lib/dhparams/openvpn.pem

let
  openvpn = {

    cert = /var/lib/acme/jonasem.com/fullchain.pem;
    key = /var/lib/acme/jonasem.com/key.pem;
  };

in
{
  security.dhparams.params.openvpn = 4096;

  services = {

    openvpn = {


      servers = {
        server = {
          autoStart = true;



        };




      };

    };
};

}
