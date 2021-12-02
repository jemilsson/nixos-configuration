#!/bin/sh
nix-channel --add https://nixos.org/channels/nixos-21.11 nixos
nix-channel --add https://nixos.org/channels/nixos-21.11-small nixos-small
nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
nix-channel --add https://nixos.org/channels/nixos-unstable-small nixos-unstable-small
nix-channel --add https://github.com/NixOS/nixos-hardware/archive/master.tar.gz nixos-hardware
nix-channel --update
