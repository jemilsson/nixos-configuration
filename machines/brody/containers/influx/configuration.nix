{ config, pkgs, ... }:
let

in
{
  imports = [
    ../public_server.nix
];

services = {
  influxdb = {
    enable = true;
  };
};

}
