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

services.home-assistant ={
   enable = true;
   config = {
     discovery = {
       enable = [
        "google_cast"
       ];
     };

   };
 };


}
