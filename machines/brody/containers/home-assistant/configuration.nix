{ config, pkgs, ... }:
let
pydeconz = pkgs.callPackage ../../../../packages/pydeconz/default.nix {};
pylgtv = pkgs.callPackage ../../../../packages/pylgtv/default.nix {};
spotipy = pkgs.callPackage ../../../../packages/spotipy/default.nix {};
secrets = import ../../secrets.nix;
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
      extraPackages = ps: with ps; [ pydeconz pylgtv ];#spotipy ];
      extraComponents = [ "media_player.spotify" ];
      #skipPip = false;
    };
   config = {
      homeassistant = {
        name = "Home";
        time_zone = "UTC";
        latitude = "59.35";
        longitude = "18.05";
        unit_system = "metric";
        elevation = 25;

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
        {
          platform = "webostv";
          host = "10.5.4.5";
          #turn_on_action = {};
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
        api_key = "A6C3A8DB60";
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
          value_template = "{{ value_json[0].temp/1000.0 }}";
        }
        { platform = "mqtt";
          state_topic = "device/2708576E636058C0/sensor/push";
          name = "CO2";
          unit_of_measurement = "ppm";
          value_template = "{{ value_json[0].co2 }}";
        }
        { platform = "mqtt";
          state_topic = "device/2708576E636058C0/sensor/push";
          name = "VOC";
          unit_of_measurement = "ppm";
          value_template = "{{ value_json[0].voc }}";
        }
        { platform = "mqtt";
          state_topic = "device/2708576E636058C0/sensor/push";
          name = "Humidity";
          unit_of_measurement = "%";
          value_template = "{{ value_json[0].hum/1000.0 }}";
        }
        { platform = "mqtt";
          state_topic = "device/2708576E636058C0/sensor/push";
          name = "PM2.5";
          unit_of_measurement = "ug/m3";
          value_template = "{{ value_json[0].pm/1000.0 }}";
        }
        {
          platform = "yr";
          name = "Current weather";
          forecast = 0;
          monitored_conditions = [
            "temperature"
            "humidity"
            "precipitation"
            "symbol"
          ];
        }
      ];

    binary_sensor = [
      { name = "monitor1";
        platform = "ping";
        host = "10.5.4.5";
        count = 1;
        scan_interval = 5;
      }
      { name = "android_tv";
        platform = "ping";
        host = "10.5.4.4";
        count = 1;
        scan_interval = 5;
      }
    ];

    fan = [
      {
        name = "Air cleaner";
        platform = "mqtt";
        command_topic = "device/2708576E636058C0/attribute/fan_speed";
        speed_command_topic = "device/2708576E636058C0/attribute/fan_speed";
        payload_on = "1";
        payload_off = "0";
        payload_low_speed = "1";
        payload_medium_speed = "2";
        payload_high_speed = "3";
        qos = 1;
      }
    ];
    light = [
      {
        name = "Air cleaner";
        platform = "mqtt";
        command_topic = "device/2708576E636058C0/attribute/brightness";
        qos = 1;
        payload_on = "4";
        payload_off = "0";
      }

    ];
    history = {};
    history_graph = {
      gr1 = {
        name = "Temperature";
        entities = [
          "sensor.temperature"
          "sensor.current_weather_temperature"
        ];
      };
    };
    logbook = {};
    wake_on_lan = {
      mac = "14:C9:13:02:02:A6";
      broadcast_address = "10.5.4.5";
    };

    automation = [

      {
        alias = "Turn on lights from dimmer";
        initial_state = "on";
        trigger = {
          platform = "event";
          event_type = "deconz_event";
          event_data = {
            id = "dimmer_switch";
            event = "1002";
            };
          };
        action = [
            {
              entity_id = "light.kitchen";
              service = "light.turn_on";
            }
          ];
      }

      {
        alias = "Turn off lights from dimmer";
        initial_state = "on";
        trigger = {
          platform = "event";
          event_type = "deconz_event";
          event_data = {
            id = "dimmer_switch";
            event = "4002";
            };
          };
        action = [
            {
              entity_id = "light.kitchen";
              service = "light.turn_off";
            }
          ];
      }

    ];

  };
 };
}
