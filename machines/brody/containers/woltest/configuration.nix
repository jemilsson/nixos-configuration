{ config, pkgs, ... }:
{
  imports = [
    ../../../../config/minimum.nix
];

networking = {
  firewall = {
    enable = false;
  };

  defaultGateway = {
    address = "10.5.4.1";
    interface = "eth0";
  };
};

environment.systemPackages = with pkgs; [
  wol
];
}
