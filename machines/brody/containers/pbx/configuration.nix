{ config, pkgs, ... }:
let
test = "test";
in
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
  unstable.freeswitch
];

services = {};

systemd.services.freeswitch = {
      enable = true;
      description = "freeswitch";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${pkgs.unstable.freeswitch}/bin/freeswitch -conf /var/run/freeswitch/conf -log /var/log/freeswitch -db /var/db/freeswitch";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
        #StateDirectory = "/var/lib/deconz";
        User = "freeswitch";
        #DeviceAllow = "char-ttyUSB rwm";
        #DeviceAllow = "char-usb_device rwm";
        #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
        LimitCORE="infinity";
        LimitNOFILE=100000;
        LimitNPROC=60000;
        LimitSTACK=250000;
        LimitRTPRIO="infinity";
        LimitRTTIME="infinity";
        IOSchedulingClass="realtime";
        IOSchedulingPriority=2;
        CPUSchedulingPolicy="rr";
        CPUSchedulingPriority=89;
      };
    };

}
