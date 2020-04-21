{ config, pkgs, ... }:
let
forceSSL = true;
enableACME = true;
in
{
  imports = [
    ../../../../config/services/nginx/nginx.nix
    ../public_server.nix
];
environment.systemPackages = with pkgs; [
];

services = {
  nginx.virtualHosts = {

        "default.jonasem.com" = {
          default = true;
          extraConfig = "return 444;";
        };

       "he.jonasem.com" = {
         inherit forceSSL enableACME;
         forceSSL = true;
         enableACME = true;
         locations = {
           "/" = {
           root = "/var/www/he.jonasem.com";
           index = "index.html";
         };
         };
       };
   };
};

}
