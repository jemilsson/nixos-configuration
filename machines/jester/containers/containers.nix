{ config, pkgs, stdenv, ... }:
{
  "testclient" = import ./troubleshooting/container.nix { pkgs = pkgs; config=config; };
}
