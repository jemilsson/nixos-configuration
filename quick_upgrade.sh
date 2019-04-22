#!/bin/sh
cd /etc/nixos/nixos-configuration
sudo git pull
sudo nixos-rebuild switch --fast
