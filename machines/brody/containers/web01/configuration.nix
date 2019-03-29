{ config, pkgs, ... }:
let
in
{
  imports = [
    ../../../../config/services/nginx/nginx.nix
    ../public_server.nix
];
environment.systemPackages = with pkgs; [
];

}
