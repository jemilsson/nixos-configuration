{ config, pkgs, ... }:
let
  faucet = pkgs.callPackage ../../../../packages/faucet/default.nix {};
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };

  defaultGateway = {
    address = "10.5.6.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
  dnsutils
];

systemd.services.faucet = {
      enable = true;
      description = "faucet";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      stopIfChanged = false;
      serviceConfig = {
        ExecStart = "${faucet}/bin/faucet  --verbose";
        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        Restart = "always";
        RestartSec = "10s";
        StartLimitInterval = "1min";
      };
    };

}
