{ config, lib, pkgs, ... }:
let
  openvpn = {
    
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
