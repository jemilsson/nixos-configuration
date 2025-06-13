{ config, lib, pkgs, stdenv, ... }:
let
  #containers = import ./containers/containers.nix { pkgs = pkgs; config = config; stdenv = stdenv; };
  cardano-node = pkgs.callPackage ../../packages/cardano-node/default.nix { };
  cardano-hw-cli = pkgs.callPackage ../../packages/cardano-hw-cli/default.nix { };
  vpp = pkgs.callPackage ../../packages/vpp/default.nix { };
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
    #./camera.nix

  ];

  nixpkgs.config.permittedInsecurePackarges = [
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

  boot.initrd.kernelModules = [ "amdgpu" ];

  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  hardware.graphics.extraPackages = with pkgs; [
  amdvlk
  vpl-gpu-rt
  ];
  # For 32 bit applications 
  hardware.graphics.extraPackages32 = with pkgs; [
    driversi686Linux.amdvlk
  ];

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
  
  hardware.ipu6.enable = true;
  hardware.ipu6.platform = "ipu6ep";
  /*
  hardware.ipu6.enable = true;
  hardware.ipu6.platform = "ipu6ep";

    boot.kernelPackages = pkgs.linuxPackages_latest.extend ( self: super: {
    ipu6-drivers = super.ipu6-drivers.overrideAttrs (
        final: previous: rec {
          src = builtins.fetchGit {
            url = "https://github.com/intel/ipu6-drivers.git";
            ref = "master";
            rev = "b4ba63df5922150ec14ef7f202b3589896e0301a";
          };
          patches = [
            "${src}/patches/0001-v6.10-IPU6-headers-used-by-PSYS.patch"
          ] ;
        }
    );
  } );

  */
  boot = {
    #extraModulePackages = with config.boot.kernelPackages; [ xmm7360-pci ];
    kernelParams = [
      "i915.force_probe=a7a1"
      #"snd_hda_intel.dmic_detect=0"
      #"i915.enable_psr=0"

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
          metric = 100;
          ips = [ "10.128.12.3/24" "2a12:5800:0:27::3/64" ];
          peers = [
          {
          publicKey = "kCvTCiqn4/mhkbWF9eKaTycAp7yHfkMYu3uEuuneFFc=";
          allowedIPs = [
                "10.128.12.0/24"
                "2a12:5800:0:27::/64"
                "2a12:5800::/29"
                "2a05:d016:865:7a00::/56"
                "10.0.0.0/8"
                "100.64.0.0/10"
                "192.168.0.0/16"
                "172.16.0.0/12"
                #"194.26.208.0/24"
                #"192.121.29.0/24"
                #"::0/0"
              ];
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

  };

  services = {
    xserver = {
      videoDrivers = [ "amdgpu" "intel" "modesetting" ];
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

  environment.systemPackages = with pkgs; [
    docker
    docker-compose
    ffmpeg
    #python37Packages.imutils
    #python37Packages.scipy
    #python37Packages.shapely
    opencl-headers
    labelImg

    #bambu-studio
    #orca-slicer

    #pkgsCross.armv7l-hf-multiplatform.buildPackages.targetPackages.glibc

    #cardano-node
    #cardano-hw-cli

    vulkan-validation-layers

    #vpp

    (chromium.override {
      commandLineArgs = [
        #"--enable-features=UseOzonePlatform"
        #"--ozone-platform=wayland"
      ];
    })

    devenv


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

  virtualisation.lxc = {
    enable = false;
    lxcfs.enable = false;
  };
  virtualisation.lxd.enable = false;





  /*
    security = {
    tpm2 = {
    enable = true;
    applyUdevRules = true;
    abrmd = {
    enable = true;
    };
    pkcs11 = {
    enable = true;
    };
    };
    };
  */


  /*
    docker-containers = {
    dataturks = {
    image = "klimentij/dataturks";
    ports = [
    "8080:9090"
    ];
    };
    };
  */

  #inherit containers;

  nixpkgs.overlays = [
    (self: super: {
      #unstable.mesa = pkgs.mesa;
      #unstable.mesa_glu = pkgs.mesa_glu;
      #unstable.mesa_noglu = pkgs.mesa_noglu;
      #unstable.mesa_drivers = pkgs.mesa_drivers;
    }
    )
  ];
  /*
  system.replaceRuntimeDependencies = [
    ({ original = pkgs.mesa; replacement = pkgs.unstable.mesa; })
    ({ original = pkgs.mesa.drivers; replacement = pkgs.unstable.mesa.drivers; })
  ];
  */

}
