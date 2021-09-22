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

  hardware.usbWwan.enable = true;

  networking = {
    hostName = "brody";
    useDHCP = false;

    #defaultGateway = {
    #  address = "10.5.20.1";
    #  interface = "br1020";
    #};

    #defaultGateway6 = {
    #  address = "2a0e:b107:330::1";
    #  interface = "br1020";
    #};

    firewall = {
      allowedTCPPorts = [ 22 ]; # 8080 8088 19999 1999 ];
      allowedUDPPorts = [ ];
      checkReversePath = false;
      extraCommands = ''
      iptables -A FORWARD -d 10.5.30.0/24 -j ACCEPT
      iptables -A FORWARD -s 10.5.30.0/24 -j ACCEPT
      iptables -A FORWARD -d 10.5.20.0/24 -j ACCEPT
      iptables -A FORWARD -s 10.5.20.0/24 -j ACCEPT
      '';
    };

    nat = {
        enable = true;
        #externalInterface = "br2";
        internalInterfaces = [ "br1020" ];
        #forwardPorts = [
        #  { destination = "10.0.0.180:22"; proto = "tcp"; sourcePort = 22; }
        #];
        #extraCommands = ''
        #  iptables -t nat -A nixos-nat-post -o enp0s22u1u2 -m mark --mark 0x1 -j MASQUERADE
        #'';
     };

    interfaces = {
      "br1020" = {
        ipv4 = {
          addresses = [
            { address = "10.5.20.1"; prefixLength = 24; }
          ];
        };
        ipv6 = {
          addresses = [
            { address = "2a0e:b107:330::4"; prefixLength = 64; }
          ];
        };

      };
      "enp0s22u1u2" = {
        useDHCP = false;
        ipv4 = {
          addresses = [
            { address = "192.168.8.10"; prefixLength = 24; }
          ];
          
          routes = [
             {
              "address" = "0.0.0.0";
              "prefixLength" = 0;
              "via" = "192.168.8.1";
              options = {
                "preference" = "10000";
              };
            }
          ];
          
        };
      };
    };

    wireguard = {
      interfaces = {
        wg0 = {
          ips = [ "10.5.254.0/31" ];
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

      ip route add unreachable 2a0e:b107:330:beef::/64
      ip route add unreachable 10.5.30.0/24
      
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
    /*
    radvd = {
      enable = true;
      config = ''


      '';
    };
    */

    lldpd = {
      enable = true;
    };
    
    dhcpd4 = {
    enable = true;
    interfaces = [ "br1020" ];
    extraConfig = ''

      option domain-name-servers 1.1.1.1;

      subnet 10.5.20.0 netmask 255.255.255.0 {
        range 10.5.20.100 10.5.20.200;
        option broadcast-address 10.5.20.255;
        option routers 10.5.20.1;
        option subnet-mask 255.255.255.0;
      }
    '';
  };
  
  };

  

  containers = containers;
  /*
  virtualisation = {
    oci-containers = {
      containers = {
        "ring-mqtt" = {
          autoStart = true;
          image = "tsightler/ring-mqtt";
          environment = {
            #DEBUG = "*";
          };
          ports = [
              "55123:55123"
          ];
          volumes = [
            "/var/lib/ring-mqtt:/data"
          ];
        };
      };
    };
  };
  */



  boot.kernelParams = [ "--- console=ttyS0,115200n8" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = "1";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.extraModulePackages = [ kernel.wireguard ];
  boot.kernelModules = [ "wireguard" ];

 environment.systemPackages = with pkgs; [
  dnsutils
  deconz

  unstable.pmacct

 ];

 /*

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
         ExecStart = "${deconz}/bin/deCONZ -platform minimal --http-listen=0.0.0.0";
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

*/

}
