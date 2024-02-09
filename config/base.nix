{ config, lib, pkgs, ... }:
let 
  nixPath = "/etc/nixPath";
in
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
      flake = lib.mkDefault "github:jemilsson/nixos-configuration";
      flags = [
      ];
      dates = "Mon..Fri 02:00";
      randomizedDelaySec = "1 h";
      persistent = true;
    };
  };

  systemd.tmpfiles.rules = [
    "L+ ${nixPath} - - - - ${pkgs.path}"
  ];

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 30d";
      dates = "Mon..Fri 03:00";
      randomizedDelaySec = "1 h";
      persistent = true;
    };
    optimise = {
      automatic = true;
      dates = [ "Mon..Fri 04:00" ];
    };

    nixPath = [ "nixpkgs=${nixPath}" ];
  };

  systemd.timers.nixos-upgrade.timerConfig.Persistent = true;

  systemd.timers.nix-gc.after = [ "nixos-upgrade.timer" ];

  systemd.timers.nix-optimise.timerConfig.Persistent = true;
  systemd.timers.nix-optimise.after = [ "nixos-upgrade.timer" "nix-gc.timer" ];



  security = {
    pam = {
      enableSSHAgentAuth = true;
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;
      };
    };
    journald = {
      extraConfig = "MaxFileSec=1year";
    };

  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
                #"openssl-1.1.1u"
              ];
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

  #time.timeZone = "Europe/Stockholm";

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


  i18n = {
    #consoleFont = "Lat2-Hack16";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "sv_SE.UTF-8/UTF-8"
      "th_TH.UTF-8/UTF-8"
    ];
  };

}

