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
      homeassistant = {
        name = "Home";
        time_zone = "UTC";
      };
      frontend = { };
      http = {
      };
      feedreader.urls = [ "https://nixos.org/blogs.xml" ];
      media_player = [
        {
            platform = "cast";
            host = "10.0.0.166";
        }
      ];
      notify = [
        {
          platform = "nfandroidtv";
          name = "AndroidTV";
          host = "10.0.0.166";
        }
      ];
  };
 };


}