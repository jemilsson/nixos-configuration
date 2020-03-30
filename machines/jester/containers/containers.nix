{ config, pkgs, stdenv, ... }:
{
  "testclient1" = import ./testclient1/container.nix { pkgs = pkgs; config=config; };
  "testclient2" = import ./testclient1/container.nix { pkgs = pkgs; config=config; };
}
