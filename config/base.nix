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

    # Configure SSH to use machine's host key for GitHub fetching
    activationScripts.setupGithubSSH = ''
      mkdir -p /root/.ssh
      cat > /root/.ssh/config <<EOF
      Host github.com
        HostName github.com
        User git
        IdentityFile /etc/ssh/ssh_host_ed25519_key
        IdentitiesOnly yes
        StrictHostKeyChecking accept-new
      EOF
      chmod 600 /root/.ssh/config
    '';

    # Display the public key for easy copying to GitHub
    activationScripts.showSSHKey = ''
      echo "================================="
      echo "Machine's SSH public key for GitHub deploy key:"
      cat /etc/ssh/ssh_host_ed25519_key.pub
      echo "================================="
    '';
  };

  systemd.tmpfiles.rules = [
    "L+ ${nixPath} - - - - ${pkgs.path}"
  ];

  boot.loader.systemd-boot.configurationLimit = 3;

  nix = {
    settings = {
      keep-derivations = false;
      keep-outputs = false;
      min-free = 1073741824;   # 1 GiB
      max-free = 3221225472;   # 3 GiB
    };
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

    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";
  };

  systemd.timers.nixos-upgrade.timerConfig.Persistent = true;

  systemd.timers.nix-gc.after = [ "nixos-upgrade.timer" ];

  systemd.timers.nix-optimise.timerConfig.Persistent = true;
  systemd.timers.nix-optimise.after = [ "nixos-upgrade.timer" "nix-gc.timer" ];

  systemd.oomd.enable = true;



  security = {
    pam = {
      # pam_rssh replaces pam_ssh_agent_auth: it understands sk-ecdsa/sk-ed25519
      # FIDO keys and sends rsa-sha2-256 flags for RSA keys, which pam_ssh_agent_auth
      # 0.10.4 cannot do (last released 2019, predates FIDO SK key support).
      rssh = {
        enable = true;
        settings.auth_key_file = "/etc/ssh/authorized_keys.d/\${user}";
      };
      services.sudo.rssh = true;
    };
  };

  services = {
    openssh = {
      enable = true;
      settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = false;

        # https://blog.qualys.com/vulnerabilities-threat-research/2024/07/01/regresshion-remote-unauthenticated-code-execution-vulnerability-in-openssh-server
        LoginGraceTime = 0;
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
          "per-directory-history"
          "zsh_codex"
        ];
      };
    };
  };

  #boot.extraModulePackages = [ config.boot.kernelPackages.wireguard ];

  environment = {
    #disrupts git
    #loginShellInit = "hostname | figlet -f big; fortune -a -s | cowsay";

    systemPackages = with pkgs; [
      (writeShellScriptBin "cargo" ''
        self_dir="$(cd "$(dirname "$0")" && pwd)"
        new_path=""
        IFS=:
        for d in $PATH; do
          [ "$d" = "$self_dir" ] && continue
          new_path="''${new_path:+$new_path:}$d"
        done
        unset IFS
        export PATH="$new_path"
        real_cargo="$(command -v cargo)"
        if [ -z "$real_cargo" ]; then
          echo "cargo wrapper: no real cargo found on PATH" >&2
          exit 127
        fi
        exec ${coreutils}/bin/nice -n 19 ${util-linux}/bin/ionice -c 3 "$real_cargo" "$@"
      '')

      #System tools
      htop
      git
      wget
      curl
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

