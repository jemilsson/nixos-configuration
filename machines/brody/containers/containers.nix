{ config, pkgs, ... }:
{
  "router1" = import ./router1/container.nix { pkgs = pkgs; config=config; };
  "router2" = import ./router2/container.nix { pkgs = pkgs; config=config; };
  "dnsmasq" = import ./dnsmasq/container.nix { pkgs = pkgs; config=config; };
  "stubby" = import ./stubby/container.nix { pkgs = pkgs; config=config; };
  "home-assistant" = import ./home-assistant/container.nix { pkgs = pkgs; config=config; };
}
