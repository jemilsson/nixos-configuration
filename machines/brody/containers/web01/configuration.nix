{ config, pkgs, ... }:
let
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
         forceSSL = true;
         enableACME = true;
         locations = {
           "/" = {
           root = "/var/www/he";
           index = "index.html";
         };
         };
       };
   };
};

}
