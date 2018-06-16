{ config, pkgs, stdenv, ... }:
{
  "router1" = import ./router1/container.nix { pkgs = pkgs; config=config; };
  "router2" = import ./router2/container.nix { pkgs = pkgs; config=config; };
  "router4" = import ./router4/container.nix { pkgs = pkgs; config=config; };
  #"dnsmasq" = import ./dnsmasq/container.nix { pkgs = pkgs; config=config; };
  "stubby" = import ./stubby/container.nix { pkgs = pkgs; config=config; };
  "home-assistant" = import ./home-assistant/container.nix { pkgs = pkgs; config=config; };
  "adserver" = import ./adserver/container.nix { pkgs = pkgs; config=config; };
  #"dhcp" = import ./dhcp/container.nix { pkgs = pkgs; config=config; };
  "dnsmasq2" = import ./dnsmasq2/container.nix { pkgs = pkgs; config=config; };
  "deconz" = import ./deconz/container.nix { pkgs = pkgs; config=config; stdenv=stdenv; };

}
