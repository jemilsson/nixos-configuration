{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/desktop_base.nix
    ../../config/kde_x11.nix
    ../../emilsson.nix
  ];

  system.stateVersion = "18.09";


  boot.kernelPackages = pkgs.unstable.linuxPackages_latest;

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

      displayManager.sddm.autoLogin = {
        user = "alicia";
        enable = true;

      };
    };
    xrdp = {
      enable = true;
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
