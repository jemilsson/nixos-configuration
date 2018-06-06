{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };

  defaultGateway = {
    address = "10.0.0.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [

];

services.nginx ={
   enable = true;

   virtualHosts."adserver" = {
     default = true;
     addSSL = true;
   };

 };


}
