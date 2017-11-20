{ config, lib, pkgs, ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ./default_users.nix
    ./known_hosts.nix
];

time.timeZone = "Europe/Stockholm";

system = {
  autoUpgrade = {
    enable = true;
    channel = https://nixos.org/channels/nixos-17.09;
    dates = "03:00";
  };
  stateVersion = "17.03";
};

security = {
  pam = {
    enableSSHAgentAuth = true;
  };
};

services = {
  openssh = {
    enable = true;
    permitRootLogin = "no";
  };
};

nixpkgs = {
  config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
    };
  };
};

programs = {
  mosh.enable = true;
  zsh = {
    enable = true;
    enableAutosuggestions = true;
    syntaxHighlighting = {
      enable = true;
    };
    promptInit = "source ${pkgs.zsh-powerlevel9k}/share/zsh-powerlevel9k/powerlevel9k.zsh-theme";
  };
};

boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

users.defaultUserShell = "/run/current-system/sw/bin/zsh";

environment = {
  #disrupts git
  #loginShellInit = "hostname | figlet -f big; fortune -a -s | cowsay";

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
    traceroute

    #Neovim
    neovim
    python35Packages.neovim
    vimPlugins.deoplete-nvim
    vimPlugins.deoplete-jedi

    #remote
    rxvt_unicode.terminfo

    #Tunneling
    wireguard

    #fun
    fortune
    cowsay
    figlet
  ];

  shellAliases = {
    "vi" = "nvim";
    "vim" = "nvim";
    "please" = "sudo";
    "plz" = "sudo";
  };

};

networking = {
  timeServers = [
    "sth1.ntp.se"
    "sth2.ntp.se"
    "ntp3.sptime.se"
    "ntp4.sptime.se"
  ];
  search = [ "jonas.systems" ];

};

nix = {
  autoOptimiseStore = true;
  gc = {
    automatic = true;
    dates = "03:30";
  };
  optimise = {
    automatic = true;
    dates = ["04:00"];

  };
};

}
