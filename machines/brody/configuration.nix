{ config, lib, pkgs, stdenv, ... }:
let
    containers = import ./containers/containers.nix { pkgs = pkgs; config=config; stdenv=stdenv; };
    deconz-full = pkgs.callPackage ../../packages/deconz/default.nix {};
    deconz = deconz-full.deCONZ;
    kernel = config.boot.kernelPackages;
in
{
  imports = [
    ../../config/server_base.nix
    ../../config/location/sesto01/configuration.nix
    ../../config/services/prometheus/node_exporter.nix
    ../../config/language/english.nix
    ./networks.nix
  ];

  system.stateVersion = "18.03";

  powerManagement = {
    enable = true;
  };

  networking = {
    hostName = "brody";
    useDHCP = false;

    defaultGateway = {
      address = "10.5.20.1";
      interface = "br1020";
    };

    defaultGateway6 = {
      address = "2a0e:b107:330::1";
      interface = "br1020";
    };

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 8080 8088 19999 1999 ];
      allowedUDPPorts = [ ];
      checkReversePath = false;
    };

    interfaces = {
      "br1020" = {
        ipv4 = {
          addresses = [
            { address = "10.5.20.4"; prefixLength = 24; }
          ];
        };
        ipv6 = {
          addresses = [
            { address = "2a0e:b107:330::4"; prefixLength = 64; }
          ];
        };

      };
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.5.254.0/31" ];
          privateKeyFile = "/var/wireguard/privatekey";
          peers = [
            {
              publicKey = "84s+/kDWRNasxQq5FyEk+kYLp00JJLGfm1i62ioFtWY=";
              endpoint = "78.141.220.154:1054";
              allowedIPs = [ "10.5.254.1/32" ];
              persistentKeepalive = 25;
            }
          ];
        };
      };
    };

    localCommands = ''
      ip link set dev wg0 mtu 1542
      ip link delete gretap1
      ip link add gretap1 type gretap local 10.5.254.0 remote 10.5.254.1
      ip link set gretap1 up mtu 1500
      ip link set gretap1 master br2000
    '';
    # ip addr add 10.5.254.2 peer 10.5.254.3 dev gretap1
  #  vswitches = {
  #    "vs-wan" = {
#
#      };
#    };
#  };

  #virtualisation = {
    #vswitch = {
    #  enable = true;
    #  resetOnStart = true;
    #  extraOvsctlCmds = ''
    #  set-fail-mode &lt;switch_name&gt; secure
    #  set Bridge <switch_name> stp_enable=true
    #
    #      '';
  #  };
  };

  services = {
    lldpd = {
      enable = true;
    };
    netdata = {
      enable = true;
    };
  };

  containers = containers;

  boot.kernelParams = [ "--- console=ttyS0,115200n8" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.extraModulePackages = [ kernel.wireguard ];
  boot.kernelModules = [ "wireguard" ];

 environment.systemPackages = with pkgs; [
  dnsutils
  python2nix
  pypi2nix

  unstable.pmacct

 ];

 users.users."deconz" = {
  createHome = true;
  isSystemUser = true;
  group = "dialout";
  home = "/home/deconz";
 };

 systemd.services.deconz = {
       enable = true;
       description = "deconz";
       after = [ "network.target" ];
       wantedBy = [ "multi-user.target" ];
       stopIfChanged = false;
       serviceConfig = {
         ExecStart = "${deconz}/bin/deCONZ -platform minimal --http-listen=::0";
         ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
         Restart = "always";
         RestartSec = "10s";
         StartLimitInterval = "1min";
         #StateDirectory = "/var/lib/deconz";
         User = "deconz";
         #DeviceAllow = "char-ttyUSB rwm";
         #DeviceAllow = "char-usb_device rwm";
         #AmbientCapabilities="CAP_NET_BIND_SERVICE CAP_KILL CAP_SYS_BOOT CAP_SYS_TIME";
       };
     };

}
