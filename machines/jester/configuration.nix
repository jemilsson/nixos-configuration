{ config, lib, pkgs, stdenv, ... }:
let
  containers = import ./containers/containers.nix { pkgs = pkgs; config = config; stdenv = stdenv; };
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

  ];

  nixpkgs.config.permittedInsecurePackages = [
                "electron-24.8.6"
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

  hardware.opengl.extraPackages = with pkgs; [
  amdvlk
  ];
  # For 32 bit applications 
  hardware.opengl.extraPackages32 = with pkgs; [
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

  boot = {
    #extraModulePackages = with config.boot.kernelPackages; [ xmm7360-pci ];
    kernelParams = [
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
    kernelPackages = pkgs.linuxPackages_6_6;

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
          ips = [ "10.128.2.3/24" "2a12:5800:0:5::3/64" ];
          peers = [
          {
          publicKey = "Z712joOcYZDyiJrynswegnIlRsebKrIskvw2rOIBX2Y=";
          allowedIPs = [
                "10.128.2.0/24"
                "2a12:5800:0:5::/64"
                #"0::/0"
                "10.0.0.0/8"
                #"0.0.0.0/0"
                "100.64.0.0/10"
              ];
          endpoint = "194.26.208.1:53";
          }
          ];
          };
        	



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

    #unstable.bambu-studio
    unstable.orca-slicer

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


  ];

  nix = { };

  hardware = {
    pulseaudio.extraConfig = ''
      load-module module-alsa-sink   device=hw:0,0 channels=4
      load-module module-alsa-source device=hw:0,6 channels=4
    '';

    #opengl = {
    #extraPackages = with pkgs; [ intel-ocl ];
    #};

  };

  virtualisation.lxc = {
    enable = true;
    lxcfs.enable = true;
  };
  virtualisation.lxd.enable = true;





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

  inherit containers;

}
