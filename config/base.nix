{ config, lib, pkgs, ... }:

{
  imports = [
    ../../hardware-configuration.nix

];

time.timeZone = "Europe/Stockholm";

system = {
  autoUpgrade = {
    enable = true;
    channel = https://nixos.org/channels/nixos-17.03;
  };
  stateVersion = "17.03";
};

services = {
  openssh.enable = true;
};

nixpkgs.config.allowUnfree = true;

programs = {
  fish.enable = true;
};

environment.systemPackages = with pkgs; [
  #System tools
  htop
  git
  wget
  curl
  python3

  #Network tools
  tcpdump
  whois
  telnet

  #Neovim
  neovim
  python35Packages.neovim
  vimPlugins.deoplete-nvim
  vimPlugins.deoplete-jedi


];

networking = {
  timeServers = [
    "sth1.ntp.se"
    "sth2.ntp.se"
    "ntp3.sptime.se"
    "ntp4.sptime.se"
  ];

};

nix = {
  autoOptimiseStore = true;
  gc = {
    automatic = true;
    dates = "04:00";
  };
};

}
