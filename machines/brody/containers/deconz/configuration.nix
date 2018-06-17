{ config, pkgs, ... }:
let
  app-full = pkgs.callPackage ./deconz/default.nix {};
  app = app-full.deCONZ;
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  defaultGateway = {
    address = "10.5.6.1";
    interface = "eth0";
  };
  firewall = {
    enable = false;
  };
};

environment.systemPackages = with pkgs; [
sqlite

];

systemd.services.deconz = {
      enable = true;
      description = "deconz";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${app}/bin/deCONZ -platform minimal --dbg-info=2";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
        #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
      };
    };


}
