{ config, lib, pkgs, ... }:
{
  imports = [
    #../../hardware-configuration.nix
    ./minimum.nix
    ./default_users.nix
    ./known_hosts.nix

  ];

  networking = {
    wireguard = {
      interfaces = {
        wg0 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          generatePrivateKeyFile = true;
        };
      };
    };
  };

  system = {
    autoUpgrade = {
      enable = true;
      #channel = https://nixos.org/channels/nixos-21.11;
      flake = "github:jemilsson/nixos-configuration";
      flags = [
      ];
      dates = "03:00";
      randomizedDelaySec = "2 h";
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
    journald = {
      extraConfig = "MaxFileSec=1year";
    };

  };

  nixpkgs = {
    config = {
      allowUnfree = true;
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

  #boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

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
      #unrar
      unzip
      dnsutils
      ncdu
      killall
      jq

      #Network tools
      tcpdump
      whois
      inetutils
      traceroute

      #Neovim
      neovim
      vimPlugins.deoplete-nvim
      vimPlugins.deoplete-jedi

      #Tunneling
      wireguard-tools

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
      "ntp.se"
      "ntp.stupi.se"
      "ntp1.sp.se"
      "ntp2.sp.se"
      "ntp3.sp.se"
      "194.58.200.20"
      "2a01:3f7::1"
    ];
    #search = [ "jonas.systems" ];

  };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "03:15";
      options = "--delete-older-than 30d";
    };
    optimise = {
      automatic = true;
      dates = [ "03:30" ];

    };
  };

  systemd.timers.nixos-upgrade.timerConfig.Persistent = true;

  systemd.timers.nix-gc.timerConfig.Persistent = true;
  systemd.timers.nix-gc.after = [ "nixos-upgrade.timer" ];

  systemd.timers.nix-optimise.timerConfig.Persistent = true;
  systemd.timers.nix-optimise.after = [ "nixos-upgrade.timer" "nix-gc.timer" ];

  i18n = {
    #consoleFont = "Lat2-Hack16";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "sv_SE.UTF-8/UTF-8"
      "th_TH.UTF-8/UTF-8"
    ];
  };

}

