{ config, pkgs, stdenv, ... }:
{
  #"router1" = import ./router1/container.nix { pkgs = pkgs; config=config; };
  #"router2" = import ./router2/container.nix { pkgs = pkgs; config=config; };
  #"router4" = import ./router4/container.nix { pkgs = pkgs; config=config; };
  #"dnsmasq" = import ./dnsmasq/container.nix { pkgs = pkgs; config=config; };
  "stubby" = import ./stubby/container.nix { pkgs = pkgs; config=config; };
  #"has01" = import ./has01/container.nix { pkgs = pkgs; config=config; };
  #"adserver" = import ./adserver/container.nix { pkgs = pkgs; config=config; };
  #"dhcp" = import ./dhcp/container.nix { pkgs = pkgs; config=config; };
  #"dnsmasq2" = import ./dnsmasq2/container.nix { pkgs = pkgs; config=config; };
  #"deconz" = import ./deconz/container.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
  "rabbitmq" = import ./rabbitmq/container.nix { pkgs = pkgs; config=config; };
  #"woltest" = import ./woltest/container.nix { pkgs = pkgs; config=config; };
  #"faucet" = import ./faucet/container.nix { pkgs = pkgs; config=config; };
  #"vxlan_a" = import ./vxlan_a/container.nix { pkgs = pkgs; config=config; };
  #"vxlan_b" = import ./vxlan_b/container.nix { pkgs = pkgs; config=config; };
  #"wgtest" = import ./wgtest/container.nix { pkgs = pkgs; config=config; };
  #"ntopng" = import ./ntopng/container.nix { pkgs = pkgs; config=config; };
  "prm01" = import ./prm01/container.nix { pkgs = pkgs; config=config; };
  "grf01" = import ./grf01/container.nix { pkgs = pkgs; config=config; };
  "web01" = import ./web01/container.nix { pkgs = pkgs; config=config; };
  "pbx" = import ./pbx/container.nix { pkgs = pkgs; config=config; };
  "avahi" = import ./avahi/container.nix { pkgs = pkgs; config=config; };

}
