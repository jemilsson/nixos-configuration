{ config, lib, pkgs, ... }:
{
  imports = [
    ../../hardware-configuration.nix
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
      channel = https://nixos.org/channels/nixos-21.11;
      dates = "03:00";
    };
  };


  security = {
    pam = {
      enableSSHAgentAuth = true;
      #p11 = {
      #  enable = true;
      #};
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
      dnsutils
      ncdu
      killall
      jq

      #Network tools
      tcpdump
      whois
      telnet
      traceroute

      #Neovim
      neovim

      #Tunneling
      wireguard
    ];

    shellAliases = {
      "vi" = "nvim";
      "vim" = "nvim";
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
    search = [ "jonas.systems" ];

  };

  nix = {
    autoOptimiseStore = true;
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
    ];
  };

}
