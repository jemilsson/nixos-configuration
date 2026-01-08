{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/desktop_base.nix
    ../../config/kde_x11.nix
    ../../config/emilsson.nix
    ../../config/language/swedish.nix
    ../../config/location/sejkg01/configuration.nix
    ./hardware-configuration.nix
  ];

  system.stateVersion = "22.05";


  #boot.kernelPackages = pkgs.linuxPackages_latest;

  networking = {
    hostName = "alicia";
    enableIPv6 = false;
    firewall.allowedTCPPorts = [ 3389 ];
  };

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  services = {
    xserver = {
      videoDrivers = [ "amdgpu" ];

      deviceSection = ''
        Option "DRI3" "1"
        Option "TearFree" "on"
      '';
    };

    displayManager.autoLogin = {
      user = "alicia";
      enable = true;
    };
    xrdp = {
      enable = false;
      #defaultWindowManager = "startkde";
    };

    lldpd = {
      enable = true;
    };
  };

  programs = {
    sway = {
      enable = true;
    };


  };

  # Define a user account. Don't forget to set a password with ‘passwd’.


  environment.systemPackages = with pkgs; [
    #unstable.tuxtyping
    gcompris
    blender
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
      #zsh-powerlevel9k = pkgs.unstable.zsh-powerlevel9k;
      #handbrake = super.handbrake.override { useGtk = true;};
    }
    )
  ];





}
