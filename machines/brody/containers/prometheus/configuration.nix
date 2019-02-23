{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };
  nameservers = [ "10.5.20.1" ];

  defaultGateway = {
    address = "10.5.20.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [

];

services = {
  prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "10.5.20.4:9100"
            ];
            labels = {
              alias = "${config.networking.hostName}";
            };
          }
        ];
      }
      {
        job_name = "snmp";
        static_configs = [
          {
            targets = [
              "10.5.20.1"
            ];
          }
        ];
        metrics_path = "/snmp";
        params = {
          module = [ "if_mib" ];
        };
        relabel_configs = [
          {
            source_labels = [ "__address__" ];
            target_label = "__param_target";
          }
          {
            source_labels = [ "__param_target" ];
            target_label = "instance";
          }
          {
            source_labels = [];
            target_label = "__address__";
            replacement = "127.0.0.1:9116";
          }
        ];
      }
  ];

    exporters = {
      snmp = {
        enable = true;

        configuration = {
          "default" = {
            "version" = 2;
            "auth" = {
              "community" = "public";
            };
          };
        };
      };
    };
  };
};

}
