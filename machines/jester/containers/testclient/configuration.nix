{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking.interfaces."eth0".useDHCP = true;

networking = {
  firewall = {
    enable = false;
  };
};
  environment.systemPackages = with pkgs; [

  ];



}
