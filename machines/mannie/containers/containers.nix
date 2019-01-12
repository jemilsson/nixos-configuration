{ config, pkgs, stdenv, ... }:
{
    "wireguard" = import ./wireguard/container.nix { pkgs = pkgs; config=config; };
}
