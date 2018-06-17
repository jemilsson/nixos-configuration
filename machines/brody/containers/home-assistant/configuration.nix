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
    address = "10.5.5.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [

];

services.home-assistant ={
   enable = true;
   autoExtraComponents = true;
   package = pkgs.home-assistant.override {
      extraPackages = ps: with ps; [ pydeconz ];
    };
   config = {
      homeassistant = {
        name = "Home";
        time_zone = "UTC";
      };
      frontend = { };
      http = {
        server_port = 8123;
      };
      feedreader.urls = [ "https://nixos.org/blogs.xml" ];
      media_player = [
        {
            platform = "cast";
            host = "10.5.4.4";
        }
      ];
      notify = [
        {
          platform = "nfandroidtv";
          name = "AndroidTV";
          host = "10.5.4.4";
        }
      ];
      deconz = {
        host = "10.0.0.180";
        port = 8080;
        api_key = "C27234693A";
      };
      logger = {
        default= "info";
        logs = {
          pydeconz = "debug";
          "homeassistant.components.deconz" = "debug";
        };
      };
  };
 };


}
