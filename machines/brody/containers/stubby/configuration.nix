{ config, pkgs, ... }:
let
in
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };
  nameservers = [ "2001:470:dc6b::1" ];

  defaultGateway6 = {
    address = "2001:470:dc6b::1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [

];

services = {
    stubby = {
      enable = true;
      listenAddresses = [ "::/0" ];
    };
  };
}
