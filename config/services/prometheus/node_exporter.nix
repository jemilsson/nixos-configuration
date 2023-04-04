{ config, lib, pkgs, ... }:
{
  #networking.firewall.allowedTCPPorts = [ 9100 ];
  services.prometheus.exporters = {
    node = {
      enable = true;
      enabledCollectors = [
        "conntrack"
        "diskstats"
        "entropy"
        "filefd"
        "filesystem"
        "loadavg"
        "mdadm"
        "meminfo"
        "netdev"
        "netstat"
        "stat"
        "time"
        "vmstat"
        "systemd"
        "logind"
        "interrupts"
        "ksmd"
      ];

      extraFlags = [
        "--collector.textfile.directory /etc/prometheus/textfile/"
      ];
    };


    systemd = {
      enable = true;
    };
  };

  /*
    config.system.nixos.version;
    config.system.nixos.release;
    config.system.nixos.codeName
    config.system.configurationRevision
  */


  environment.etc."/prometheus/textfile/nixosVersion".text = "${config.system.nixos.version}";
  environment.etc."/prometheus/textfile/nixosRelease".text = "${config.system.nixos.release}";
  environment.etc."/prometheus/textfile/nixosCodeName".text = "${config.system.nixos.codeName}";
  environment.etc."/prometheus/textfile/nixosConfigurationRevision".text = "${toString config.system.configurationRevision}";

}



