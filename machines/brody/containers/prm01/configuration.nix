{ config, pkgs, ... }:
let
interface_lookups = [
  {
    labelname = "ifDescr";
    labels = [ "ifIndex" ];
    oid = "1.3.6.1.2.1.2.2.1.2";
    type = "DisplayString";
  }
  {
    labelname = "ifName";
    labels = [ "ifIndex" ];
    oid = "1.3.6.1.2.1.31.1.1.1.1";
    type = "DisplayString";
  }
  {
    labelname = "ifAlias";
    labels = [ "ifIndex" ];
    oid = "1.3.6.1.2.1.31.1.1.1.18";
    type = "DisplayString";
  }
];
system_lookups = [
  {
    labelname = "sysDescr";
    labels = [  ];
    oid = "1.3.6.1.2.1.1.1.0";
    type = "DisplayString";
  }
  {
    labelname = "sysName";
    labels = [ ];
    oid = "1.3.6.1.2.1.1.5.0";
    type = "DisplayString";
  }
  {
    labelname = "sysLocation";
    labels = [ ];
    oid = "1.3.6.1.2.1.1.6.0";
    type = "DisplayString";
  }
  {
    labelname = "sysContact";
    labels = [ ];
    oid = "1.3.6.1.2.1.1.4.0";
    type = "DisplayString";
  }
];

jnxOperatingLookups = [
{
  labelname = "jnxOperatingDescr";
  labels = [ "jnxOperatingContentsIndex" "jnxOperatingL1Index" "jnxOperatingL2Index" "jnxOperatingL3Index" ];
  oid = "1.3.6.1.4.1.2636.3.1.13.1.5";
  type = "DisplayString";
}
{
  labelname = "jnxOperatingChassisDescr";
  labels = [ "jnxOperatingContentsIndex" "jnxOperatingL1Index" "jnxOperatingL2Index" "jnxOperatingL3Index" ];
  oid = "1.3.6.1.4.1.2636.3.1.13.1.18";
  type = "DisplayString";
}

];

jnxOperatingIndexes = [
{
  labelname = "jnxOperatingContentsIndex";
  type = "Integer";
}
{
  labelname = "jnxOperatingL1Index";
  type = "Integer";
}
{
  labelname = "jnxOperatingL2Index";
  type = "Integer";
}
{
  labelname = "jnxOperatingL3Index";
  type = "Integer";
}
];


in
{
  imports = [
    ../../../../config/minimum.nix
    ../public_server.nix
];

environment.systemPackages = with pkgs; [

];

services = {
  prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "brody.jonas.systems:9100"
            ];
            labels = {
              alias = "${config.networking.hostName}";
            };
          }
        ];
      }
      {
        job_name = "hass";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "has01.sesto01.jonas.systems:8123"
            ];
            labels = {
              alias = "${config.networking.hostName}";
            };
          }
        ];
        metrics_path = "/api/prometheus";
        scheme = "http";
        params = {
          api_password = ["8wzUfUfLa6ZuewFd4j2UxtVu"];
        };
      }
      {
        job_name = "snmp";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "10.5.20.1"
              "10.5.20.2"
              "10.5.20.3"
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
          "if_mib" = {
            "version" = 2;
            "auth" = {
              "community" = "public";
            };
            walk = [
              "1.3.6.1.2.1.2.2.1.1"
              "1.3.6.1.2.1.2.2.1.3"
              "1.3.6.1.2.1.2.2.1.4"
              "1.3.6.1.2.1.2.2.1.13"
              "1.3.6.1.2.1.2.2.1.14"
              "1.3.6.1.2.1.2.2.1.15"
              "1.3.6.1.2.1.31.1.1.1.10"
              "1.3.6.1.2.1.31.1.1.1.11"
              "1.3.6.1.2.1.31.1.1.1.12"
              "1.3.6.1.2.1.31.1.1.1.13"
              "1.3.6.1.2.1.31.1.1.1.14"
              "1.3.6.1.2.1.31.1.1.1.15"
              "1.3.6.1.2.1.31.1.1.1.6"
              "1.3.6.1.2.1.31.1.1.1.7"
              "1.3.6.1.2.1.31.1.1.1.8"
              "1.3.6.1.2.1.31.1.1.1.9"
              "1.3.6.1.2.1.1.3"

              "1.3.6.1.2.1.31.1.1"

              "1.3.6.1.4.1.2636.3.1.13.1.1"
              "1.3.6.1.4.1.2636.3.1.13.1.2"
              "1.3.6.1.4.1.2636.3.1.13.1.3"
              "1.3.6.1.4.1.2636.3.1.13.1.4"
              "1.3.6.1.4.1.2636.3.1.13.1.5"
              "1.3.6.1.4.1.2636.3.1.13.1.6"
              "1.3.6.1.4.1.2636.3.1.13.1.7"
              "1.3.6.1.4.1.2636.3.1.13.1.8"
              "1.3.6.1.4.1.2636.3.1.13.1.9"
              "1.3.6.1.4.1.2636.3.1.13.1.10"
              "1.3.6.1.4.1.2636.3.1.13.1.11"
              "1.3.6.1.4.1.2636.3.1.13.1.12"
            ];
            metrics = [
              {
                name = "ifIndex";
                oid = "1.3.6.1.2.1.2.2.1.1";
                type = "gauge";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifType";
                oid = "1.3.6.1.2.1.2.2.1.3";
                type = "gauge";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCOutOctets";
                oid = "1.3.6.1.2.1.31.1.1.1.10";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCOutUcastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.11";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCOutMulticastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.12";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCOutBroadcastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.13";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHighSpeed";
                oid = "1.3.6.1.2.1.31.1.1.1.15";
                type = "gauge";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCInOctets";
                oid = "1.3.6.1.2.1.31.1.1.1.6";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCInUcastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.7";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCInMulticastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.8";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifHCInBroadcastPkts";
                oid = "1.3.6.1.2.1.31.1.1.1.9";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifMtu";
                oid = "1.3.6.1.2.1.2.2.1.4";
                type = "gauge";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifInDiscards";
                oid = "1.3.6.1.2.1.2.2.1.13";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifInErrors";
                oid = "1.3.6.1.2.1.2.2.1.14";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "ifInUnknownProtos";
                oid = "1.3.6.1.2.1.2.2.1.15";
                type = "counter";
                indexes = [
                  {
                    labelname = "ifIndex";
                    type = "Integer";
                  }
                ];
                lookups = interface_lookups;
              }
              {
                name = "sysUpTime";
                oid = "1.3.6.1.2.1.1.3";
                type = "counter";
                lookups = system_lookups;
              }
              {
                name = "jnxOperatingContentsIndex";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.1";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingL1Index";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.2";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingL2Index";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.3";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingL3Index";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.4";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingState";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.6";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingTemp";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.7";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingCPU";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.8";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingISR";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.9";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingDRAMSize";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.10";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingBuffer";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.11";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }
              {
                name = "jnxOperatingHeap";
                oid = "1.3.6.1.4.1.2636.3.1.13.1.12";
                type = "gauge";
                indexes = jnxOperatingIndexes;
                lookups = jnxOperatingLookups;
              }

            ];
          };
        };
      };
    };
  };
};

}
