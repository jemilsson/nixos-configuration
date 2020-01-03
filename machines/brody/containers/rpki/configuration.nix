{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };
};

systemd = {
  services = {
    gortr = {
      enable = true;
      description = "gortr";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${pkgs.unstable.gortr}/bin/gortr -bind :8282 -verify=false";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
        #StateDirectory = "/var/lib/deconz";
        #User = "deconz";
        #DeviceAllow = "char-ttyUSB rwm";
        #DeviceAllow = "char-usb_device rwm";
        #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
      };
    };
  };
};

    environment.systemPackages = with pkgs; [
      unstable.gortr
    ];



}
