{ config, lib, pkgs, ... }:
{

programs = {
  zsh = {
    enable = true;
    enableAutosuggestions = true;
    syntaxHighlighting = {
      enable = true;
    };
    ohMyZsh = {
      enable =true;
      theme = "agnoster";
    };
  };
};

users.defaultUserShell = "/run/current-system/sw/bin/zsh";

environment = {
  systemPackages = with pkgs; [
    #System tools
    htop
    wget
    curl

    #Network tools
    tcpdump
    whois
    traceroute
  ];
};

networking = {
  search = [ "jonas.systems" ];
};

}
