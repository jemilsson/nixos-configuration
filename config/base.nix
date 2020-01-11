{ config, lib, pkgs, ... }:
{
  imports = [
    ../../hardware-configuration.nix
    ./minimum.nix
    ./default_users.nix
    ./known_hosts.nix

];

system = {
  autoUpgrade = {
    enable = true;
    channel = https://nixos.org/channels/nixos-19.09;
    dates = "03:00";
  };
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
    passwordAuthentication = false;
  };
  mingetty = {
    helpLine = "test";
  };
  emacs = {
    enable = true;
    defaultEditor = true;
  };
  journald = {
      extraConfig = "MaxFileSec=1year";
  };

};

nixpkgs = {
  config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      unstable = import <nixos-unstable> {
        config = config.nixpkgs.config;
      };
      unstable-small = import <nixos-unstable-small> {
        config = config.nixpkgs.config;
      };
    };
  };
};

programs = {
  mosh.enable = true;
  zsh = {
    ohMyZsh = {
      plugins = [
        "pass"
        "sudo"
        "systemd"
        "web-search"
        "jsontools"
        "mosh"
        "python"
        "wd"
      ];
    };
  };
};

boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

environment = {
  #disrupts git
  #loginShellInit = "hostname | figlet -f big; fortune -a -s | cowsay";

  systemPackages = with pkgs; [
    #System tools
    htop
    git
    wget
    curl
    neofetch
    unrar
    ncdu
    #python3

    #Network tools
    tcpdump
    whois
    telnet
    traceroute

    #Neovim
    neovim
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

    #DNS
    stubby
  ];

  shellAliases = {
    "vi" = "nvim";
    "vim" = "nvim";
    "please" = "sudo";
    "plz" = "sudo";
  };

};

time.timeZone = "Europe/Stockholm";

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
    options = "--delete-older-than 90d";
  };
  optimise = {
    automatic = true;
    dates = ["04:00"];

  };
};

systemd.timers.nix-gc.timerConfig.Persistent = true;

i18n = {
  consoleFont = "Lat2-Hack16";
  supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "sv_SE.UTF-8/UTF-8"
    "th_TH.UTF-8/UTF-8"
  ];
};

}
