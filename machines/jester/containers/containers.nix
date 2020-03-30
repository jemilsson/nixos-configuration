{ config, pkgs, stdenv, ... }:
{
  "testclient" = import ./testclient/container.nix { pkgs = pkgs; config=config; };
}
