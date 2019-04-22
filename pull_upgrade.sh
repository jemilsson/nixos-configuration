#!/bin/sh
cd /etc/nixos/nixos-configuration
sudo git pull
sudo sh /etc/nixos/nixos-configuration/add_channels.sh
sudo nixos-rebuild switch --upgrade
