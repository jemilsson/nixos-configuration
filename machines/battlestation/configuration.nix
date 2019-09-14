{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/desktop_base.nix
    ../../config/i3_x11.nix
    ../../config/location/sesto01/configuration.nix
    ../../config/language/english.nix
  ];

  system.stateVersion = "18.09";

  hardware.cpu.amd.updateMicrocode = true;

  networking = {
    hostName = "battlestation";

    firewall.allowedTCPPorts = [ 3389 ];

    interfaces = {
      "lan-2" = {
        useDHCP = true;
      };
      "old-lan" = {
        useDHCP = true;
      };
      "management" = {
        useDHCP = true;
      };
      "lan" = {
        useDHCP = true;
        mtu = 9000;
      };
      "test" = {
        useDHCP = true;
      };

      "enp8s0" = {
        mtu = 9000;
      };

    };
    vlans = {
      "management" = {
        id = 5;
        interface = "enp8s0";
      };
      "lan-2" = {
        id = 4;
        interface = "enp8s0";
      };
      "old-lan" = {
        id = 1;
        interface = "enp8s0";
      };
      "lan" = {
        id = 1020;
        interface = "enp8s0";
      };
      "test" = {
        id = 1025;
        interface = "enp8s0";
      };
    };
    #useNetworkd = true;
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  virtualisation.libvirtd.enable = true;

  #boot.kernelPackages = pkgs.linuxPackages_latest_hardened;
  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

  services = {
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

    redshift = {
      enable = true;
      latitude = "59.35";
      longitude = "18.05";

    };
  };


  programs = {
    java.package = pkgs.jre;
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

  unstable.steam
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
