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
