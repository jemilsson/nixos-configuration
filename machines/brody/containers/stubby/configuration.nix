{ config, pkgs, ... }:
let
in
{
  imports = [
    ../public_server.nix
];

environment.systemPackages = with pkgs; [

];

services = {
    stubby = {
      enable = true;
      listenAddresses = [ "::/0" ];
    };
  };
}
