#!/bin/sh
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
sudo nix-channel --add https://nixos.org/channels/nixos-unstable-small nixos-unstable-small
sudo nix-channel --add https://nixos.org/channels/nixos-19.03 nixos
sudo nix-channel --update
