{ config, lib, pkgs, ... }:
let
libedgetpu-dev = pkgs.callPackage ../../packages/libedgetpu-dev/default.nix {};
libedgetpu-max = pkgs.callPackage ../../packages/libedgetpu-max/default.nix {};
python3-edgetpu = pkgs.callPackage ../../packages/python3-edgetpu/default.nix {};
in
{
environment = {
  systemPackages = with pkgs; [
  libedgetpu-dev
  libedgetpu-max
  python3-edgetpu
  ];
}
