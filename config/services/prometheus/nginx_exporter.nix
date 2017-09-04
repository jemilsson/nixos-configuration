{ config, lib, pkgs, ... }:
{
  #networking.firewall.allowedTCPPorts = [ 9100 ];
  services.prometheus.nginxExporter = {
    enable = true;
    listenAddress = "127.0.0.1";
  };
}
