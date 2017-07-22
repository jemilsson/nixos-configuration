# My nixos configuration

```
sudo rm -r /etc/nixos/nixos-configuration/
sudo rm /etc/nixos/configuration.nix
cd /etc/nixos
sudo git clone https://github.com/jemilsson/nixos-configuration.git
set -x HOSTNAME (hostname -f)
sudo ln -sr /etc/nixos/nixos-configuration/machines/$HOSTNAME.nix  configuration.nix
sudo nix-channel --add https://nixos.org/channels/nixos-unstable nixos
sudo nixos-rebuild switch --upgrade

```
