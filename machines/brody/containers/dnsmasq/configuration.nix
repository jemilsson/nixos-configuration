{ config, pkgs, ... }:
let
  configFile = pkgs.writeText "stubby.yaml" ''
listen_addresses:
- 0.0.0.0@53
'';
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking.firewall = {
  allowedUDPPorts = [ 53 ];
};

networking.defaultGateway = {
  address = "10.0.0.1";
  interface = "eth0";
};
environment.systemPackages = with pkgs; [
  stubby
  dnsutils
];

services.dnsmasq = {
  enable = true;
  extraConfig = ''
    domain-needed
    bogus-priv

    domain=ynglingagatan.local
    expand-hosts
    local=/ynglingagatan.local/

    listen-address=10.0.0.5

    dhcp-range=lan,10.0.0.100,10.0.0.200
    dhcp-option=lan,3,10.0.0.1
    dhcp-option=lan,6,10.0.0.5

    server=127.0.0.1

    '';
};


systemd.services.stubby = {
      enable = true;
      description = "stubby";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${pkgs.stubby}/bin/stubby  -C ${configFile} -l";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };


}
