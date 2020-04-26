{ config, pkgs, ... }:
let

in
{
  imports = [
    ../public_server.nix
];

environment.systemPackages = with pkgs; [
  influxdb
];

services = {
  influxdb = {
    enable = true;
  };
};

}
