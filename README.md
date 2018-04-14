# My nixos configuration

```
#!/bin/sh
sudo rm -r /etc/nixos/nixos-configuration/
sudo rm /etc/nixos/configuration.nix
cd /etc/nixos
sudo git clone https://github.com/jemilsson/nixos-configuration.git
#set -x HOSTNAME (hostname -f)
sudo ln -sr /etc/nixos/nixos-configuration/machines/$HOSTNAME/configuration.nix  configuration.nix
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos-unstable
sudo nix-channel --add https://nixos.org/channels/nixos-18.03 nixos
sudo nix-channel --update
sudo nixos-rebuild switch --upgrade

```
