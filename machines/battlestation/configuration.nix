{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/desktop_base.nix
    ../../config/services/kvm/kvm.nix
    ../../config/i3_x11.nix
    ../../config/location/sesto01/configuration.nix
    ../../config/language/english.nix
  ];

  system.stateVersion = "18.09";

  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostName = "battlestation";

    firewall.allowedTCPPorts = [ 3389 ];

    defaultGateway = {
      address = "10.5.20.1";
      interface = "br0";
    };

    interfaces = {
      "br0" = {
        ipv4 = {
          addresses = [
            { address = "10.5.20.18"; prefixLength = 24; }
          ];
        };
        ipv6 = {
          addresses = [
            { address = "2a0e:b107:330::18"; prefixLength = 64; }
          ];
        };
      };
    };

    bridges."br0".interfaces = [ "enp8s0" ];

    #useNetworkd = true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  #boot.kernelPackages = pkgs.linuxPackages_latest_hardened;
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  services = {
    wakeonlan.interfaces = [
      { interface = "enp8s0"; method = "password"; password = "00:11:22:33:44:55"; }
    ];


    #Logitech G29
    udev = {
      packages = with pkgs; [
        usb-modeswitch-data
        usb-modeswitch
      ];
      extraRules = ''
        ATTR{idVendor}=="046d", ATTR{idProduct}=="c24f", RUN+="${pkgs.usb-modeswitch}/lib/udev/usb_modeswitch '/%k'"
      '';
    };

    xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
      Option "DRI3" "1"
      Option "TearFree" "on"
      '';
    };
    xrdp = {
      enable = true;
      defaultWindowManager = "i3";
    };

    lldpd = {
      enable = true;
    };

    avahi = {
      enable = true;
      nssmdns = true;
      ipv6 = true;
      ipv4 = true;
      interfaces = [ "lan" ];

      publish = {
        enable = false;
      };
    };

  };


  programs = {
    java.package = pkgs.jdk;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.

 environment.systemPackages = with pkgs; [
  #teamspeak_client
  vscode
  virtmanager

  taskwarrior

  elmPackages.elm

  freerdp

  unstable.minecraft

  xca

  unstable.wasabiwallet
 ];

 nixpkgs.overlays = [
     (self: super: {
       #mesa = pkgs.unstable.mesa;
       #mesa_glu = pkgs.unstable.mesa_glu;
       #mesa_noglu = pkgs.unstable.mesa_noglu;
       #mesa_drivers = pkgs.unstable.mesa_drivers;
       #xorg.xf86videoamdgpu = pkgs.unstable.xorg.xf86videoamdgpu;
       #steam-run = pkgs.unstable.steam-run;
       #steam = pkgs.unstable.steam;
       #steam-runtime = pkgs.unstable.steam-runtime;
       #steam-runtime-wrapped = pkgs.unstable.steam-runtime-wrapped;
       #steam-fonts = pkgs.unstable.steam-fonts;
       #steam-chrootenv = pkgs.unstable.steam-chrootenv;
       #vulkan-loader = pkgs.unstable.vulkan-loader;
       zsh-powerlevel9k = pkgs.unstable.zsh-powerlevel9k;
       handbrake = super.handbrake.override { useGtk = true;};
     }
     )
   ];





}
