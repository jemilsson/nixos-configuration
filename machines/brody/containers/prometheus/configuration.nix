{ config, pkgs, ... }:
let
pydeconz = pkgs.callPackage ../../../../packages/pydeconz/default.nix {};
pylgtv = pkgs.callPackage ../../../../packages/pylgtv/default.nix {};
spotipy = pkgs.callPackage ../../../../packages/spotipy/default.nix {};
secrets = import ../../secrets.nix;
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

];

services = {
  prometheus = {
    enable = true;
    scrapeConfigs = [
      {
        job_name = "node";
        scrape_interval = "10s";
        static_configs = [
          {
            targets = [
              "10.5.20.4:9100"
            ];
            labels = {
              alias = "${config.networking.hostName}";
            };
          }
        ];
      }
    ];
  };
};

}
