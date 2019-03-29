{ config, pkgs, ... }:

{
  imports = [
    ../../../../config/minimum.nix
    ../public_server.nix
];

environment.systemPackages = with pkgs; [

];

services = {
  grafana = {
    enable = true;
    analytics = {
      reporting.enable = true;
    };
    auth = {
      anonymous = {
        enable = true;
        org_role = "Editor";
        org_name = "org";
      };
    };
    addr = "2001:470:dc6b::10";
  };
};

}
