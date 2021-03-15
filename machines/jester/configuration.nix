{ config, lib, pkgs, stdenv, ... }:
let
  containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
in
{
  imports = [
    #<nixos-hardware/lenovo/thinkpad/x1/7th-gen>
    ../../config/laptop_base.nix
    ../../config/services/kvm/kvm.nix
    ../../config/i3_x11.nix
    ../../config/language/english.nix
    ../../config/software/tensorflow.nix
  ];
  system.stateVersion = "19.03";

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    #kernelPackages = pkgs.unstable.linuxPackages_latest;

    binfmt.emulatedSystems = [ "aarch64-linux" "armv7l-linux"];
    };

  networking = {
    hostName = "jester";

    bridges = {
      br0 = {
        interfaces = [];
      };
      br1 = {
        interfaces = [];
      };
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = ["10.50.0.37/32"];
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
          ips = ["10.111.255.253/32" "10.112.255.253/32"];
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
      };
    };
  };

 services = {
   xserver = {
     videoDrivers = [ "intel" "modesetting" ];
   };
   undervolt = {
     enable = false;
   };

   fprintd = {
     enable = true;
   };

   ofono.enable = true; 

   dbus.packages = [ pkgs.unstable.hsphfpd ]
 };

 environment.systemPackages = with pkgs; [
  docker
  docker-compose
  ffmpeg
  python37Packages.imutils
  python37Packages.scipy
  python37Packages.shapely
  opencl-headers
  labelImg

  pkgsCross.armv7l-hf-multiplatform.buildPackages.targetPackages.glibc



  unstable.hsphfpd
 ];

 nix = {
   extraOptions = ''
   extra-platforms = aarch64-linux arm-linux
   '';
 };

 hardware = {
  pulseaudio.extraConfig = ''
    load-module module-alsa-sink   device=hw:0,0 channels=4
    load-module module-alsa-source device=hw:0,6 channels=4
  '';

  opengl = {
    extraPackages = with pkgs; [ intel-ocl ];
  };

 };

systemd.services = {
  hsphfpd = {
        after = [ "bluetooth.service" ];
        requires = [ "bluetooth.service" ];
        wantedBy = [ "bluetooth.target" ];

        description = "A prototype implementation used for connecting HSP/HFP Bluetooth devices";
        serviceConfig.ExecStart = "${pkgs.unstable.hsphfpd}/bin/hsphfpd.pl";
      };
};



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
