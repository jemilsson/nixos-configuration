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



}
