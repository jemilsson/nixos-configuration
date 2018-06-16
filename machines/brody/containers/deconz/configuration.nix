{ config, pkgs, ... }:
let
  app = import ./deconz/default.nix { pkgs = pkgs; stdenv = stdenv; fetchurl=fetchrurl; perl=perl; dpkg=dpkg };
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
    allowedUDPPorts = [ ];
  };
};

environment.systemPackages = with pkgs; [

];

systemd.services.deconz = {
      enable = true;
      description = "deconz";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${app}/bin/deCONZ ";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };


}
