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
    { prefix = "::/0"; metric = 9999; }
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

  boot.initrd.kernelModules = [ ];
  boot.blacklistedKernelModules = [ "pn533_usb" "pn533" ];

  boot.kernel.sysctl."net.ipv4.tcp_mtu_probing" = 1;

  systemd.services.restart-fprintd-on-resume = {
    description = "Restart fprintd after resume from sleep";
    wantedBy = [ "post-resume.target" ];
    after = [ "post-resume.target" ];
    script = "systemctl restart fprintd";
    serviceConfig.Type = "oneshot";
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
      "xe.force_probe=a7a1"       # Use xe driver for Raptor Lake Iris Xe
      "i915.force_probe=!a7a1"    # Tell i915 to skip this GPU
      "i915.modeset=0"            # Make i915 fully inert (xe owns the GPU)
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
        iproute2 = pkgs.iproute2;
        gnugrep = pkgs.gnugrep;
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






  security.tpm2 = {
    enable = true;
    abrmd.enable = true;
  };

  # fafnir: TPM-backed SSH agent + FIDO authenticator + age plugin.
  services.fafnir = {
    enable       = true;
    approval     = "fprintd";
    enableRsa    = true;
    rsaBits      = 2048;
    powerledPath = "/sys/class/leds/tpacpi::power";
    agentSockPaths = [ "$XDG_RUNTIME_DIR/gnupg/S.gpg-agent.ssh" ];
  };

  # gpg-agent ssh socket — forwarded through fafnir so GPG-auth keys
  # remain available behind the same SSH_AUTH_SOCK.
  programs.gnupg.agent.settings = {
    enable-ssh-support = "";
  };
  systemd.user.sockets.gpg-agent-ssh = {
    unitConfig = {
      Description = "GnuPG cryptographic agent (ssh-agent emulation)";
      Documentation = "man:gpg-agent(1) man:ssh-add(1) man:ssh-agent(1) man:ssh(1)";
    };
    socketConfig = {
      ListenStream = "%t/gnupg/S.gpg-agent.ssh";
      FileDescriptorName = "ssh";
      Service = "gpg-agent.service";
      SocketMode = "0600";
      DirectoryMode = "0700";
    };
    wantedBy = [ "sockets.target" ];
  };
  programs.ssh.extraConfig = ''
    Match host * exec "${pkgs.runtimeShell} -c '${config.programs.gnupg.package}/bin/gpg-connect-agent --quiet updatestartuptty /bye >/dev/null 2>&1'"
  '';
}
