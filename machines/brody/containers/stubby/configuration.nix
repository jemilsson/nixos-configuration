{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

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
        ExecStart = "${pkgs.stubby}/bin/stubby";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };


}
