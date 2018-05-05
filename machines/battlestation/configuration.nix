{ config, lib, pkgs, ... }:
{
  imports = [
    ../../config/x_desktop.nix
  ];

  networking = {
    hostName = "battlestation";
    enableIPv6 = false;
  };

  boot.loader.grub = {
      enable = true;
      version = 2;
      device = "/dev/sda";
    };

  boot.kernelModules = [ "kvm-amd" "kvm-intel" ];
  virtualisation.libvirtd.enable = true;



  services = {
    xserver = {
      videoDrivers = [ "amdgpu-pro" ];

      deviceSection = ''
      Option "DRI3" "1"
      Option "TearFree" "on"
      '';
    };
    xrdp = {
      enable = true;
      defaultWindowManager = "i3";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
 users.extraUsers.user = {
    isNormalUser = true;
    uid = 1003;
    home = "/home/user/";
    extraGroups = [ "wheel" "networkmanager" ];
    useDefaultShell = true;
 };

 environment.systemPackages = with pkgs; [
  i3pystatus
  python3
  teamspeak_client
  sway
  #unstable.way-cooler
  wayland
  #weston
  #unstable.alacritty
  alacritty
  pptp
  unstable.vulkan-loader
  vscode
  virtmanager

  handbrake

  taskwarrior

  elmPackages.elm
  elmPackages.elm-reactor

  oraclejdk
  insomnia

  sqlite

  freerdp
 ];

 nixpkgs.overlays = [
     (self: super: {
       #mesa = pkgs.unstable.mesa;
       #mesa_glu = pkgs.unstable.mesa_glu;
       #mesa_noglu = pkgs.unstable.mesa_noglu;
       #mesa_drivers = pkgs.unstable.mesa_drivers;
       #xorg.xf86videoamdgpu = pkgs.unstable.xorg.xf86videoamdgpu;
       steam-run = pkgs.unstable.steam-run;
       steam = pkgs.unstable.steam;
       steam-runtime = pkgs.unstable.steam-runtime;
       steam-runtime-wrapped = pkgs.unstable.steam-runtime-wrapped;
       steam-fonts = pkgs.unstable.steam-fonts;
       steam-chrootenv = pkgs.unstable.steam-chrootenv;
       vulkan-loader = pkgs.unstable.vulkan-loader;
       zsh-powerlevel9k = pkgs.unstable.zsh-powerlevel9k;
       handbrake = super.handbrake.override { useGtk = true;};
     }
     )
   ];





}
