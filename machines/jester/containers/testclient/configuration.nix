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
  environment.systemPackages = with pkgs; [
      
  ];



}
