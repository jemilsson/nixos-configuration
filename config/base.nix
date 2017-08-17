{ config, lib, pkgs, ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ./default_users.nix

];

time.timeZone = "Europe/Stockholm";

system = {
  autoUpgrade = {
    enable = true;
    channel = https://nixos.org/channels/nixos-17.03;
    dates = "03:00";
  };
  stateVersion = "17.03";
};

services = {
  openssh.enable = true;
};

nixpkgs.config.allowUnfree = true;

programs = {
  fish.enable = true;
  mosh.enable = true;
};

environment = {



  systemPackages = with pkgs; [
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

    #remote
    rxvt_unicode.terminfo
  ];

  shellAliases = {
    "vi" = "nvim";
    "vim" = "nvim";
  };

};

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
  optimise = {
    automatic = true;
    dates = "03:30";

  };
};

}
