{ config, pkgs, stdenv, ... }:
{
  "troubleshooting" = import ./troubleshooting/container.nix { pkgs = pkgs; config=config; };
}
