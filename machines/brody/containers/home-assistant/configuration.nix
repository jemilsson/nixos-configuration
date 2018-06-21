{ config, pkgs, ... }:
let
pydeconz = pkgs.callPackage ../../../../packages/pydeconz/default.nix {};
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };
  nameservers = [ "10.5.6.4" ];

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
      #extraComponents = ps: with ps; [ "pip" "pydeconz" ];
      #skipPip = false;
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
        api_key = "4FC0D086AF";
      };
      mqtt = {
        broker = "rabbitmq.ynglingagatan.local";
      };

      logger = {
        default= "info";
        logs = {
          pydeconz = "debug";
          "homeassistant.components.deconz" = "debug";
        };
      };

      sensor = [
        { platform = "mqtt";
          state_topic = "device/2708576E636058C0/sensor/push";
          name = "Temperature";
          unit_of_measurement = "°C";
          value_template = "{{ value_json.temp/1000.0 }}";
        }
      ];
    };
 };
}
