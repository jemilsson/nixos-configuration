{ config, lib, pkgs, ... }:

{
  imports = [
    ./desktop_base.nix
    ./x11.nix
  ];

}
