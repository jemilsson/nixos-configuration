#!/bin/sh
sudo rm -r /etc/nixos/nixos-configuration/
sudo rm /etc/nixos/configuration.nix
cd /etc/nixos
sudo git clone https://github.com/jemilsson/nixos-configuration.git
sudo ln -sr /etc/nixos/nixos-configuration/machines/$HOSTNAME/configuration.nix configuration.nix
sudo sh add_channels.sh
sudo nixos-rebuild switch --upgrade
