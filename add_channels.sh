#!/bin/sh
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://nixos.org/channels/nixos-unstable-small nixos-unstable-small
nix-channel --add https://nixos.org/channels/nixos-20.03 nixos
nix-channel --update
