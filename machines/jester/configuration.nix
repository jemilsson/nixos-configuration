{ config, lib, pkgs, stdenv, ... }:
let
  #containers = import ./containers/containers.nix { pkgs = pkgs; config = config; stdenv = stdenv; };
  #cardano-node = removed - no longer needed
  #cardano-hw-cli = removed - no longer needed  
  vpp = pkgs.jemilsson.vpp;
  claudia = pkgs.jemilsson.claudia;
  fit-web = pkgs.jemilsson.fit-web;
  fit-entire-website = pkgs.jemilsson.fit-entire-website;
  fit-main = pkgs.jemilsson.fit-main;

  wg2IPv4Prefixes = [
    { prefix = "10.128.12.0/24"; }
    { prefix = "10.0.0.0/8"; }
    { prefix = "100.64.0.0/10"; }
    { prefix = "192.168.0.0/16"; }
    { prefix = "172.16.0.0/12"; }
    { prefix = "160.79.104.0/23"; }  # Claude code
  ];

  wg2IPv6Prefixes = [
    { prefix = "2a12:5800:0:27::/64"; }
    { prefix = "2a12:5800::/29"; }
    { prefix = "2a05:d016:865:7a00::/56"; }
    { prefix = "2607:6bc0::/48"; }   # Claude code
    { prefix = "::/0"; metric = 50000; }
  ];

  parsePrefix = s: let
    parts = lib.splitString "/" s;
  in {
    address = builtins.elemAt parts 0;
    prefixLength = lib.toInt (builtins.elemAt parts 1);
  };

  prefixToRoute = p: let
    parsed = parsePrefix p.prefix;
  in parsed // lib.optionalAttrs (p ? metric) {
    options.metric = toString p.metric;
  };

  wg2AllowedIPs = map (p: p.prefix) (wg2IPv4Prefixes ++ wg2IPv6Prefixes);
  wg2IPv4Routes = map prefixToRoute wg2IPv4Prefixes;
  wg2IPv6Routes = map prefixToRoute wg2IPv6Prefixes;
in
{
  imports = [
    #<nixos-hardware/lenovo/thinkpad/x1/7th-gen>
    ../../config/laptop_base.nix
    ../../config/services/kvm/kvm.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
    #../../config/software/tensorflow.nix
    #../../packages/vpp/vpp.nix
    ./hardware-configuration.nix
    #./graphiti.nix
    #./mcpo.nix
    ./camera.nix
    ./netns-claude-glecom.nix
    ./pi-lens.nix

  ];

  nixpkgs.config.permittedInsecurePackages = [
                #"electron-24.8.6"
];



  #programs.sway.extraOptions = [
  #  "WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0"
  #];

  #programs.sway.extraSessionCommands = ''
  #  WLR_DRM_DEVICES=/dev/dri/card1:/dev/dri/card0
  #'';


  environment.variables = {
    WLR_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
    #WLR_BACKEND = "vulkan";
  };

  boot.kernelPatches = [
    {
      name = "intel-mst-reprobe-fix";
      patch = ./intel-mst-reprobe-fix.patch;
    }
  ];

  boot.initrd.kernelModules = [ ];
  boot.blacklistedKernelModules = [ "pn533_usb" "pn533" "xe" ];

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

  systemd.services.restart-fprintd-on-resume = {
    description = "Restart fprintd after resume from sleep";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    script = "systemctl restart fprintd";
    serviceConfig.Type = "oneshot";
  };

  # Reaper for orphaned `ssh nix-builder@somchai.jonasem.com` sessions.
  #
  # When `nix build` runs against the somchai remote builder, the local
  # nix-daemon spawns a child `ssh nix-builder@somchai ... nix-daemon --stdio`
  # per build. If the parent `nix build` dies abnormally (SIGKILL, terminal
  # closed without `ssh -O exit`, agent crash), the SSH process is reparented
  # to nix-daemon (the system service) and never reaped: nix-daemon is still
  # alive, and SSH's ServerAliveInterval does not fire while the remote end
  # is healthy. The orphan keeps the per-builder upload lock, so all
  # subsequent `nix build` invocations queue forever behind it.
  #
  # This is the jester-side mirror of the `nix-daemon-stdio-reaper` unit that
  # runs on somchai itself (which handles the remote-side `nix-daemon --stdio`
  # zombies). Together they bound the lifetime of abandoned builder sessions.
  #
  # Logic: only kill ssh-nix-builder PIDs if the nix-daemon has no active
  # temproots entries (the daemon creates these during any build or copy, so
  # their presence means a legitimate build is in flight), and only after the
  # SSH process has been alive for >30 minutes.
  systemd.services.nix-ssh-builder-reaper = {
    description = "Reap orphaned ssh nix-builder@somchai sessions";
    path = [ pkgs.coreutils pkgs.procps pkgs.util-linux ];
    serviceConfig.Type = "oneshot";
    script = ''
      MAX_IDLE_S=1800   # 30 min
      LOG=/var/log/nix-ssh-builder-reaper.log
      ts=$(date -Iseconds)
      killed=0
      for pid in $(pgrep -f 'ssh nix-builder@somchai\.jonasem\.com' || true); do
        [ -d "/proc/$pid" ] || continue

        # Active build: nix-daemon holds temproots entries during any build/copy.
        # Checking these is more reliable than matching client process names.
        if [ -d /nix/var/nix/temproots ] && [ "$(ls -A /nix/var/nix/temproots 2>/dev/null)" ]; then
          continue
        fi

        etime=$(ps -o etimes= -p "$pid" 2>/dev/null | tr -d ' ')
        [ -n "$etime" ] || continue
        [ "$etime" -gt "$MAX_IDLE_S" ] || continue

        echo "$ts ORPHAN ssh-nix-builder pid=$pid etime=''${etime}s -> SIGKILL" >>"$LOG"
        kill -9 "$pid" 2>/dev/null || true
        killed=$((killed+1))
      done
      [ "$killed" -gt 0 ] && echo "$ts reaped $killed orphan ssh session(s)" >>"$LOG"
      exit 0
    '';
  };

  systemd.timers.nix-ssh-builder-reaper = {
    description = "Periodic reap of orphaned ssh nix-builder@somchai sessions";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "10min";
      OnUnitActiveSec = "10min";
      Unit = "nix-ssh-builder-reaper.service";
    };
  };

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics.extraPackages = with pkgs; [
  vpl-gpu-rt
  ];
  # For 32 bit applications 
  # hardware.graphics.extraPackages32 = with pkgs; [
  #   # RADV is used by default, no need for amdvlk
  # ];

  /*
  age.rekey = {
    # Obtain this using `ssh-keyscan` or by looking it up in your ~/.ssh/known_hosts
    hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEtJIhxEVsyKN/7fUBN4DYFoU6wgMJZbC8+hZk7Rv4Cx";
    # The path to the master identity used for decryption. See the option's description for more information.
    masterIdentities = [ ../../age/jonas-yubikey-7447013.pub ];
    #masterIdentities = [ "/home/myuser/master-key" ]; # External master key
    #masterIdentities = [ "/home/myuser/master-key.age" ]; # Password protected external master key
  };

  age.secrets.secret1.rekeyFile = ./secrets/secret1.age;
  age.secrets.secret1.generator.script = "alnum";

  environment.etc."secret1" = {
    source = config.age.secrets.secret1.path;
  };
  */
  
  #users.users.user1.passwordFile = config.age.secrets.secret1.path;

  system.stateVersion = "23.05";
  boot = {
    extraModulePackages = with config.boot.kernelPackages; [ acpi_call ];
    kernelModules = [ "acpi_call" "uhid" ];
    kernelParams = [
      "mem_sleep_default=s2idle"  # Only sleep mode available (firmware has no S3)
    ];
    loader = {
      systemd-boot =
        {
          enable = true;
          graceful = true;
        };
      efi.canTouchEfiVariables = true;
    };
    #kernelPackages = pkgs.linuxPackages_6_6;
    #kernelPackages = pkgs.unstable.linuxPackages_latest;

    binfmt.emulatedSystems = [ ];
  };

  # Disambiguate the two RTK USB-C panels (they ship with identical EDID
  # serials, which confuses wlroots/Hyprland and prevents distinct
  # per-output position rules). The kernel-assigned DP connector names
  # are unstable across reboots (we've seen DP-5/DP-6 and DP-7/DP-8),
  # but the two panels always land on adjacent connectors. Override every
  # odd DP-N: exactly one of the two panels picks up the modified EDID,
  # the other keeps its native one, so they end up with distinct serials.
  hardware.display.outputs."DP-1".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-3".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-5".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-7".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-9".edid = "rtk-dp8.bin";
  hardware.display.outputs."DP-11".edid = "rtk-dp8.bin";
  hardware.display.edid.packages = [
    (pkgs.runCommand "rtk-edid" { } ''
      mkdir -p "$out/lib/firmware/edid"
      cp ${./edid/rtk-dp8.bin} "$out/lib/firmware/edid/rtk-dp8.bin"
    '')
  ];

  networking = {
    hostName = "jester";
    getaddrinfo.enable = false;

    bridges = {
      br0 = {
        interfaces = [ ];
      };
      br1 = {
        interfaces = [ ];
      };
    };

    wireguard = {
      interfaces = {
        /*
          wg0 = {
          ips = [ "10.50.0.37/32" ];
          peers = [
          {
          publicKey = "IR9lBjFR2qX4UmgML5oBykUgrAzqOzhaNpF+xjD8L3k=";
          allowedIPs = [
          "10.50.0.0/16"
          ];
          endpoint = "13.48.43.75:123";
          }

          ];
          };
        
          wg1 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          generatePrivateKeyFile = true;
          ips = [ "10.111.255.253/32" "10.112.255.253/32" ];
          peers = [
          {
          publicKey = "zYgI7WYsKHNh70oZvdHDPKCeqKeEdsQbAIxtlNGSw2c=";
          allowedIPs = [
          "10.111.0.0/16"
          ];
          endpoint = "18.198.12.235:123";
          }

          {
          publicKey = "Uv6JEWpVPBAt44WBRWmyGRYtF0k7mYm2vRKmkOArtUw=";
          allowedIPs = [
          "10.112.0.0/16"
          ];
          endpoint = "54.75.127.255:123";
          }

          ];
          };

        */

        
          
          wg2 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          allowedIPsAsRoutes = false;
          metric = 100;
          ips = [ "10.128.12.3/24" "2a12:5800:0:27::3/64" ];
          peers = [
          {
          publicKey = "kCvTCiqn4/mhkbWF9eKaTycAp7yHfkMYu3uEuuneFFc=";
          allowedIPs = wg2AllowedIPs;
          endpoint = "194.26.208.1:51822";
          }
          ];
          };
        
        /*

          
          wg3 = {
          privateKeyFile = "/var/lib/wireguard/privatekey";
          ips = [ "10.128.12.3/24" "2a12:5800:0:27::3/64" ];
          peers = [
          {
          publicKey = "Z712joOcYZDyiJrynswegnIlRsebKrIskvw2rOIBX2Y=";
          allowedIPs = [
                "10.128.12.0/24"
                "2a12:5800:0:27::/64"
                "10.0.0.0/8"
                "172.16.0.0/12"
                "192.168.0.0/16"
                "100.64.0.0/10"
                "192.121.29.0/24"
                "194.26.208.0/24"
                "2a12:5800::/29"
                #"0::/0"
                #"0.0.0.0/0"
                
              ];
          endpoint = "194.26.208.43:53";
          }
          ];
          };

          */
        	



      };
    };

    interfaces = {
      #"enp48s0u2u1.102" = {
      #  useDHCP = true;
      #};
      #"enp48s0u2u1.150" = {
      #  useDHCP = true;
      #};

      wlp0s20f3.ipv4.routes = [
        {
            address = "194.26.208.1";
            prefixLength = 32;

        }
        {
            address = "194.26.208.43";
            prefixLength = 32;

        }
      ];
      wg2.ipv4.routes = wg2IPv4Routes;
      wg2.ipv6.routes = wg2IPv6Routes;
    };

    vlans = {
      #"enp48s0u2u1.102" = {
      #  id = 102;
      #  interface = "enp48s0u2u1u2";
      #};
      #"enp48s0u2u1.150" = {
      #  id = 150;
      #  interface = "enp48s0u2u1u2";
      #};
    };

  dhcpcd = {
    enable = true;
    extraConfig = "
    define 108 uint32 ipv6only_preferred
    request ipv6only_preferred
    ";
  };

  networkmanager.dispatcherScripts = [
    {
      type = "basic";
      source = pkgs.replaceVars ./prefer-ipv4-fallback.sh {
        iputils = pkgs.iputils;
      };
    }
  ];

  };

  services = {
    xserver = {
      videoDrivers = [ "modesetting" ];
    };
    undervolt = {
      enable = false;
    };

    fprintd = {
      enable = true;
    };

    ofono.enable = true;

    teamviewer.enable =true;

    clatd = {
      enable = true;
      settings = {
        plat-prefix = "64:ff9b::/96";
      };
    };

  };

  networking.firewall.extraCommands = ''
    # Allow IPv6 forwarding for clatd
    ip6tables -I FORWARD -i clat -j ACCEPT
    ip6tables -I FORWARD -o clat -j ACCEPT
  '';

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    #python37Packages.imutils
    #python37Packages.scipy
    #python37Packages.shapely
    opencl-headers
    labelImg
    tesseract5  # OCR tool with all language support

    #bambu-studio
    #orca-slicer

    #pkgsCross.armv7l-hf-multiplatform.buildPackages.targetPackages.glibc

    #cardano-node
    #cardano-hw-cli

    vulkan-validation-layers

    #vpp
    
    #claudia
    
    # fit-web  # Needs additional dependencies
    # fit-entire-website  # Needs additional dependencies
    # fit-main  # Main FIT GUI application (needs work)

    # chromium is in desktop_base.nix with --remote-debugging-port=9222

    unstable.telegram-desktop
    whatsapp-electron

    bun
    sox

    claude-code

    nix-tcp-proxy

    #devenv


  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  nix = { 
    extraOptions = ''
        trusted-users = root jonas

        extra-substituters = https://devenv.cachix.org
        extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
    '';
    settings.experimental-features = [ "nix-command" "flakes" ];
    settings.builders-use-substitutes = true;

  };

  hardware = {

    #firmware = [
    #  pkgs.unstable.ivsc-firmware
    #];

    /*
    pulseaudio.extraConfig = ''
      load-module module-alsa-sink   device=hw:0,0 channels=4
      load-module module-alsa-source device=hw:0,6 channels=4
    '';
    */

    #opengl = {
    #extraPackages = with pkgs; [ intel-ocl ];
    #};

  };






  # Allow jonas to restart fprintd without a password (needed to clear stale
  # D-Bus claims after hyprlock exits without releasing the sensor).
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units" &&
          action.lookup("unit") == "fprintd.service" &&
          action.lookup("verb") == "restart" &&
          subject.user == "jonas") {
        return polkit.Result.YES;
      }
    });
  '';

  security.tpm2 = {
    enable = true;
    # abrmd is a userspace TPM resource manager that competes with the
    # kernel's /dev/tpmrm0 for session slots. fafnir uses tpmrm0 by
    # default; running both yields "Esys called in bad sequence"
    # errors when they independently juggle TPM state. Disable abrmd
    # unless a legacy app explicitly needs a dbus/socket TCTI.
    abrmd.enable = false;
  };

  # fafnir: TPM-backed SSH agent + FIDO authenticator + age plugin.
  services.fafnir = {
    enable       = true;
    approval     = "fprintd";
    enableRsa    = true;
    rsaBits      = 2048;
    autoLockIdleSecs = 28800;
    powerledPath = "/sys/class/leds/tpacpi::power";
    # YubiKey OpenPGP keys are now reached via fafnir-openpgp's own
    # ssh-agent socket (scdaemon passthrough). fafnir's main agent
    # forwards to it, so SSH_AUTH_SOCK on the TPM agent gets both
    # the TPM identity and the card auth key.
    agentSockPaths = [ "$XDG_RUNTIME_DIR/fafnir/openpgp-ssh.sock" ];
    secretService.enable = true;
  };

  # fafnir-keepassxc-bridge: native-messaging host for KeePassXC-Browser
  # (Chromium/Firefox), serving credentials out of fafnir's vault.
  services.fafnir-keepassxc-bridge = {
    enable = true;
    users  = [ "jonas" ];
  };

  # fafnir-wallet: Ledger-Nano-emulating Solana HD wallet daemon
  # (TPM-protected BIP39 seed, exposed as a UHID Ledger device).
  services.fafnir-wallet = {
    enable = true;
    users  = [ "jonas" ];
  };

  # fafnir-openpgp: gpg-agent replacement, TPM-backed. Mutually exclusive
  # with the upstream gpg-agent user service for the listed users.
  services.fafnir-openpgp = {
    enable = true;
    users  = [ "jonas" ];
  };

  # Bind fafnir-openpgp to the XDG runtime gnupg socket path so gpg
  # tools find it at the standard location (gpgconf --list-dirs
  # agent-socket returns %t/gnupg/S.gpg-agent, not ~/.gnupg/S.gpg-agent).
  # Disable the competing gpg-agent sockets so they don't lock the
  # YubiKey first via their own scdaemon.
  systemd.user.services.fafnir-openpgp = {
    serviceConfig.ExecStartPre = lib.mkAfter
      [ "${pkgs.coreutils}/bin/mkdir -p %t/gnupg" ];
    serviceConfig.Environment  = lib.mkAfter [ "GNUPGHOME=%t/gnupg" ];
    unitConfig.Conflicts       = "gpg-agent.service";
  };
  systemd.user.sockets.gpg-agent.enable       = lib.mkForce false;
  systemd.user.sockets.gpg-agent-extra.enable = lib.mkForce false;

  # Raise per-user systemd default LimitNOFILE so transient units (e.g.
  # `systemd-run --user -p LimitNOFILE=...`) can be granted >524288 fds.
  # Required by magicblock-validator (RocksDB) for ER integration tests.
  systemd.user.extraConfig = ''
    DefaultLimitNOFILE=1048576
  '';

  # The module defaults to graphical-session.target, but WAYLAND_DISPLAY
  # is only imported into systemd's environment by the Hyprland exec-once
  # that starts hyprland-session.target. Binding to that target ensures
  # fafnir-prompt can connect to the compositor.
  systemd.user.services.fafnir = {
    unitConfig.After  = lib.mkForce [ "fafnir-openpgp.service" "hyprland-session.target" ];
    unitConfig.Wants  = lib.mkForce [ "fafnir-openpgp.service" ];
    unitConfig.PartOf = lib.mkForce [ "hyprland-session.target" ];
    wantedBy          = lib.mkForce [ "hyprland-session.target" ];
  };
  systemd.user.services.fafnir-passkey = {
    unitConfig.After  = lib.mkForce [ "fafnir.service" "hyprland-session.target" ];
    unitConfig.PartOf = lib.mkForce [ "hyprland-session.target" ];
    wantedBy          = lib.mkForce [ "hyprland-session.target" ];
  };

  # fafnir-secret-service owns org.freedesktop.secrets on jester,
  # so disable gnome-keyring's secrets component (default-enabled
  # in config/appearance.nix) to avoid the D-Bus name race.
  services.gnome.gnome-keyring.enable = lib.mkForce false;

  # gpg-agent SSH emulation has been retired — fafnir-openpgp serves
  # the YubiKey auth subkey directly on its own ssh-agent socket via
  # scdaemon passthrough, and fafnir's main agent forwards to it.
  programs.ssh.extraConfig = ''

    Host somchai.jonasem.com
      User nix-builder
      IdentitiesOnly yes
      IdentityAgent none
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      ProxyCommand /home/jonas/workspace/private-nixos-configuration/machines/somchai/somchai-proxy.sh %h %p
      ControlMaster auto
      ControlPath /tmp/nix-ssh-%r@%h:%p
      ControlPersist 120
      ConnectTimeout 120
      ServerAliveInterval 60
      ServerAliveCountMax 10
      TCPKeepAlive yes
  '';

  # Use somchai (AWS EC2 c7i in ap-southeast-7) as a remote nix builder.
  # Root SSHes via the host ed25519 key (jester-tpm), authorized for jonas
  # on somchai via the shared ssh-keys.nix.
  # Prevent nix-daemon crash on boot: Settings static initializer dereferences
  # HOME before nscd is ready. Setting HOME explicitly avoids the race.
  systemd.services.nix-daemon.environment.HOME = "/root";

  nix.distributedBuilds = true;
  nix.settings.max-jobs = 1; # 0 breaks preferLocalBuild=true derivations (e.g. /etc/issue)
  # somchai is an EC2 spot instance woken on demand via Lambda from the
  # ProxyCommand; cold boot is 60-90s. Keep this generous so nix-daemon
  # doesn't yank the SSH handshake before the wake completes.
  nix.settings.connect-timeout = 360;
  # Prevent "download buffer is full" → daemon crashes when streaming large
  # NARs from the remote builder / S3 cache. Default 64 MiB is too small.
  nix.settings.download-buffer-size = 1024 * 1024 * 1024; # 1 GiB
  # Reliability pack (2026-05-01): the somchai remote-build path lost
  # entire builds to "Nix daemon disconnected unexpectedly" mid-NAR
  # when the SSH multiplex channel saturated.
  # Limit substituter parallelism so substituting paths back from
  # somchai/cache.nixos.org doesn't exhaust SSH channel slots and starve
  # the build itself. Default 16 is way too aggressive for our link.
  nix.settings.max-substitution-jobs = 4;
  # Fall back to local build when somchai is unreachable instead of failing.
  nix.settings.fallback = true;
  # Larger TCP backoff on remote-build SSH so the link survives the
  # post-build-hook S3 push hiccup that briefly blocks somchai's
  # nix-daemon write side.
  nix.settings.stalled-download-timeout = 300;
  # Pull from somchai's S3 binary cache using a read-only IAM credential.
  # somchai-nix-read in /root/.aws/credentials: s3:GetObject + s3:ListBucket only.
  nix.settings.substituters = lib.mkAfter [
    "s3://somchai-nix-cache-723173433317?region=ap-southeast-7&profile=somchai-nix-read"
  ];
  nix.settings.trusted-public-keys = lib.mkAfter [
    "somchai-cache-1:NBIJCnDzlLzG9mNpHf4iEv17xZ+9ceF5+NBBdYxambc="
  ];
  nix.buildMachines = [{
    hostName = "somchai.jonasem.com";
    sshUser = "nix-builder";
    sshKey = "/etc/ssh/ssh_host_ed25519_key";
    systems = [ "x86_64-linux" ];
    # Lowered from 8 → 4. Eight parallel `nix-daemon --stdio` channels
    # over a single SSH connection saturated the multiplex on
    # large-closure builds (fafnir-ui-apk, decentgaming-contracts).
    # Four still saturates somchai's CPU but keeps SSH responsive.
    maxJobs = 4;
    speedFactor = 4;
    supportedFeatures = [ "kvm" "nixos-test" "big-parallel" "benchmark" ];
    protocol = "ssh-ng";
  }];
  programs.ssh.knownHosts.somchai = {
    hostNames = [ "somchai.jonasem.com" "2406:da14:8b88:b701:ce5e:831b:b719:c940" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEsY31lwQd6bxClPwdH3kGDfKjSEcBmTUoxeP+7aaXMY";
  };

  # Software debounce for MX Anywhere 3S which has bouncing left-click switch
  environment.etc."libinput/local-overrides.quirks".text = ''
    [Logitech MX Anywhere 3S Bounce Fix]
    MatchUdevType=mouse
    MatchName=*Logitech MX Anywhere 3S*
    ModelLogitechBustypeRollover=1
  '';
}
